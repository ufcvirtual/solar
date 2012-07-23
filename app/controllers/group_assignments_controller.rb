include GroupAssignmentHelper
include FilesHelper

class GroupAssignmentsController < ApplicationController

  before_filter :prepare_for_group_selection #, :only => [:list]
  # before_filter :user_related_to_assignment?, :except => [:index]
  before_filter :can_import?, :only => [:import_groups_page, :import_groups]
  # load_and_authorize_resource

  # lista trabalhos em grupo
  def index
    #authorize! :list, Portfolio
    group_id = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id

    #traz apenas os trabalhos de grupo dessa turma
    @assignments = GroupAssignment.all_by_group_id(group_id)
  end

  # exibe detalhes do trabalho e os grupos
  def show_assignment

    @assignment = Assignment.find(params[:assignment_id])
    @groups = group_assignments(@assignment.id)
    @students_without_group = no_group_students(@assignment.id)
    @assignment_files = []
    send_assignments = SendAssignment.all(:conditions => ["assignment_id = ? AND user_id = ?", @assignment["id"], session["warden.user.user.key"][1][0]])
    send_assignments.each_with_index{ |send_assignment, idx|
      @assignment_files += AssignmentFile.find_all_by_send_assignment_id(send_assignment.id) unless (send_assignments[idx].group_assignment_id != nil)
    }

    # @group_situation
    
  end

  ##
  # Gerenciamento de grupos da atividade
  ##
  def manage_groups

    @assignment = Assignment.find(params[:assignment_id])

    # clicou em "salvar"
    unless params['btn_cancel']

      begin
        GroupAssignment.transaction do

          # deleção de grupos
          groups_that_cant_delete = []
          all_deleted_groups_ids = []
          unless params['deleted_groups_divs_ids'].blank?
            all_deleted_groups_ids = params['deleted_groups_divs_ids'].collect{ |group| group.tr('_', ' ').split[1]}
            params['deleted_groups_divs_ids'].each{ |deleted_group| 
              group_not_deleted = delete_group(deleted_group.tr('_', ' ').split[1])
              groups_that_cant_delete += group_not_deleted unless group_not_deleted.nil?
            }
          end

          # criação/edição de grupos
          params['groups'].each { |group|
            group_id = group[1]['group_id']
            group_participants_ids = (group[1]['student_ids'].split).collect{|participant| participant.to_i} unless group[1]['student_ids'].nil?
            # se não forem alunos sem grupo
            unless group_id.nil?
              group_name = group[1]['group_name']
              # novo grupo
              if group_id == '0'
                group_assignment = GroupAssignment.create!(:assignment_id => params[:assignment_id], :group_name => group_name)
              # grupo já existente
              else
                group_assignment = GroupAssignment.find(group_id)
                group_assignment.update_attributes!(:group_name => group_name)
              end
            end
            change_students_group(group_assignment, group_participants_ids, params[:assignment_id]) unless (!can_remove_group?(group_id) and all_deleted_groups_ids.include?("#{group_id}"))
          }

          @students_without_group = no_group_students(@assignment.id)

          respond_to do |format|
            format.html { render 'assignment_div', :layout => false }
          end
        end
      rescue Exception => error
        render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
      end

    # clicou em "cancelar"
    else
      respond_to do |format|
        format.html { render 'assignment_div', :layout => false }
      end
    end

  end

  ##
  # Página de importação de grupos (lightbox)
  # => @assignments: todas as atividades da turma acessada pelo usuário no momento
  # => @assignment_id: a atividade que irá importar os grupos
  ##
  def import_groups_page
    group_id = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id
    @assignments = GroupAssignment.all_by_group_id(group_id)
    @assignment_id = params[:assignment_id]
    render :layout => false
  end

  ##
  # Importação de grupos
  ##
  def import_groups
    import_from_assignment_id = params[:assignment_id_import_from]
    import_to_assignment_id = params[:assignment_id]

    groups_to_import = GroupAssignment.find_all_by_assignment_id(import_from_assignment_id)

    unless groups_to_import.empty?
      groups_to_import.each do |group_to_import|
        group_imported = GroupAssignment.create(:group_name => group_to_import.group_name, :assignment_id => import_to_assignment_id)
        group_participants_to_import = GroupParticipant.find_all_by_group_assignment_id(group_to_import.id)
        unless group_participants_to_import.empty?
          group_participants_to_import.each do |participant_to_import|
            GroupParticipant.create(:group_assignment_id => group_imported.id, :user_id => participant_to_import.user_id)
          end
        end
      end
    end

    flash[:notice] = t(:group_assignment_import_success)
    redirect_to group_assignments_url
  end

  def download_single_file
    assignment_id = params[:assignment_id]
    assignment_file = AssignmentFile.find_by_id(params[:file_id])
    error_redirect = {:controller => :group_assignments, :action => :show_assignment, :assignment_id => assignment_id}
    download_file(error_redirect, assignment_file.attachment.path, assignment_file.attachment_file_name)
  end

  def download_all_files_zip
    assignment_files = params[:all_files].collect{|file_id| AssignmentFile.find(file_id)}
    error_redirect = {:controller => :group_assignments, :action => :show_assignment, :assignment_id => assignment_files.first.send_assignment.assignment_id}
    path_zip = make_zip_files(assignment_files, 'attachment_file_name', 'Portfolio')
    download_file(error_redirect, path_zip)
  end

private
  
  def delete_group(group_id)
    if can_remove_group?(group_id)
      participants = group_participants(group_id)
      participants.each{|participant| GroupParticipant.find(participant["id"]).destroy}
      GroupAssignment.find(group_id).destroy
    end
  end

  def can_remove_group?(group_id)
    return SendAssignment.find_all_by_group_assignment_id(group_id).empty?
  end

  ##
  # Método que realiza as mudanças de um grupo e realiza as trocas de alunos
  # => group_assingment: objeto do grupo_assignment a ser alterado/criado
  # => students: lista dos ids dos participantes do grupo passado
  ##
  def change_students_group(group_assignment, students_ids, assignment_id)
    begin 
      unless students_ids.nil?
        students_ids.each{|student_id|
          # grupo atual do aluno
          group_participant = GroupParticipant.includes(:group_assignment).where("group_participants.user_id = ? AND 
                                                                                  group_assignments.assignment_id = ?",
                                                                                  student_id, assignment_id).first

          # arquivos enviados pelo aluno para grupo atual
          student_files_group = AssignmentFile.includes(:send_assignment).where("send_assignments.group_assignment_id = ? AND 
                                                                                    assignment_files.user_id = ?", 
                                                                                    group_participant["group_assignment_id"], student_id).first unless group_participant.nil?
          # send_assignment do grupo atual
          group_send_assignment = SendAssignment.find_by_group_assignment_id(group_participant["group_assignment_id"]) unless group_participant.nil?

          # send_assignment do grupo ao qual aluno tentará ser movido
          choosen_group_send_assignment = SendAssignment.find_by_group_assignment_id(group_assignment["id"]) unless group_assignment.nil?

          # a não ser que:
          # => aluno tenha enviado arquivos ao grupo atual OU send_assignment do grupo existe sem arquivos e foi avaliado
          # => novo grupo tenha um send_assignment e foi avaliado
          student_can_be_removed_from_current_group = (student_files_group.nil? and (group_send_assignment.nil? or group_send_assignment.grade.nil?))
          student_can_be_moved_to_choosen_group = choosen_group_send_assignment.nil? or choosen_group_send_assignment["grade"].nil?

          if (student_can_be_removed_from_current_group and student_can_be_moved_to_choosen_group)
            unless group_assignment.nil?
              if group_participant.nil?
                GroupParticipant.create!(:group_assignment_id => group_assignment["id"], :user_id => student_id)
              elsif group_participant["group_assignment_id"] != group_assignment["id"]
                group_participant.update_attributes!(:group_assignment_id => group_assignment["id"]) # unless student_sent_files_to_current_group
              end
            else
              group_participant.delete unless group_participant.nil? 
            end
          end
        }
      end
    rescue Exception => error
      raise "#{error.message}"
    end
  end

end