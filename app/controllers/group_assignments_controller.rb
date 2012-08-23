include GroupAssignmentHelper
include FilesHelper
include PortfolioHelper

class GroupAssignmentsController < ApplicationController

  before_filter :prepare_for_group_selection, :user_related_to_assignment?, :user_related_to_assignment?
  before_filter :can_import?, :only => [:import_groups_page, :import_groups]
  before_filter :assignment_in_time?, :except => [:assignment]
  load_and_authorize_resource

  ##
  # Exibe detalhes do trabalho e os grupos
  ##
  def group_activity
    @assignment             = Assignment.find(params[:assignment_id])
    @groups                 = group_assignments(@assignment.id)
    @students_without_group = no_group_students(@assignment.id)
    @assignment_files       = AssignmentEnunciationFile.find_all_by_assignment_id(@assignment.id)

    @send_assignment        = []
    @can_manage_group       = []
    @quantity_files_sent    = []
    @tooltip_group          = []
    @tooltip_delete_group   = []
    @tooltip_student        = []

    @groups.each_with_index do |group, idx|
      @send_assignment[idx]      = SendAssignment.find_by_group_assignment_id(group["id"])
      @can_manage_group[idx]     = (@send_assignment[idx].nil? or @send_assignment[idx]["grade"].nil?) ? true : false
      @tooltip_group[idx]        = @can_manage_group[idx] ? nil : t(:already_evaluated)
      files_sent                 = (@send_assignment[idx].nil? ? nil : AssignmentFile.find_all_by_send_assignment_id(@send_assignment[idx].id))
      @quantity_files_sent[idx]  = (files_sent.nil? ? "0" : files_sent.size)
      delete_group               = (!files_sent.nil? or @can_manage_group[idx]) ? @tooltip_group[idx] : t(:already_sent_files) 
      @tooltip_delete_group[idx] = delete_group.nil? ? nil : t(:group_assignment_delete_error) + ", " + delete_group.to_s
    end

  end

  ##
  # Gerenciamento de grupos da atividade
  ##
  def manage_groups
    @assignment        = Assignment.find(params[:assignment_id])
    deleted_groups_ids = params['deleted_groups_divs_ids'].blank? ? [] : params['deleted_groups_divs_ids'].collect{ |group| group.tr('_', ' ').split[1] }
    
    # clicou em "salvar"
    unless params['btn_cancel']

      begin
        GroupAssignment.transaction do

          # deleção de grupos
            deleted_groups_ids.each do |deleted_group_id| 
              delete_group(deleted_group_id)
            end

          # criação/edição de grupos
          params['groups'].each do |group|
            group_id = group[1]['group_id']
            group_participants_ids = (group[1]['student_ids'].split).collect{|participant| participant.to_i} unless group[1]['student_ids'].nil?
            # se não forem alunos sem grupo
            unless group_id.nil?
              group_name = group[1]['group_name']
              # novo grupo
              if group_id == '0'
                group_assignment = GroupAssignment.create!(:assignment_id => @assignment.id, :group_name => group_name)
              # grupo já existente
              else
                group_assignment = GroupAssignment.find(group_id)
                group_assignment.update_attributes!(:group_name => group_name)
              end
            end
            change_students_group(group_assignment, group_participants_ids, @assignment.id) unless (!can_remove_group?(group_id) and deleted_groups_ids.include?("#{group_id}"))
          end

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
    group_id       = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id
    @assignments   = GroupAssignment.all_by_group_id(group_id)
    @assignment_id = params[:assignment_id]
    render :layout => false
  end

  ##
  # Importação de grupos
  ##
  def import_groups
    import_from_assignment_id = params[:assignment_id_import_from]
    import_to_assignment_id   = params[:assignment_id]
    groups_to_import          = GroupAssignment.find_all_by_assignment_id(import_from_assignment_id)

    unless groups_to_import.empty? or !assignment_in_time?
      groups_to_import.each do |group_to_import|
        group_imported               = GroupAssignment.create(:group_name => group_to_import.group_name, :assignment_id => import_to_assignment_id)
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
  def change_students_group(new_group_assignment, students_ids, assignment_id)
    begin 
      unless students_ids.nil?
        students_ids.each do |student_id|

          # grupo_participant atual do aluno
          current_group_participant = GroupParticipant.includes(:group_assignment).where("group_participants.user_id = ? AND 
                                                      group_assignments.assignment_id = ?", student_id, assignment_id).first

          # arquivos enviados pelo aluno para grupo atual
          student_files_current_group = AssignmentFile.includes(:send_assignment).where("send_assignments.group_assignment_id = ?
           AND assignment_files.user_id = ?", current_group_participant["group_assignment_id"], student_id).first unless current_group_participant.nil?
          # send_assignment do grupo atual
          current_group_send_assignment = SendAssignment.find_by_group_assignment_id(current_group_participant["group_assignment_id"]) unless current_group_participant.nil?

          # send_assignment do grupo ao qual aluno tentará ser movido
          choosen_group_send_assignment = SendAssignment.find_by_group_assignment_id(new_group_assignment["id"]) unless new_group_assignment.nil?

          student_can_be_removed_from_current_group = (student_files_current_group.nil? and (current_group_send_assignment.nil? or current_group_send_assignment.grade.nil?))
          student_can_be_moved_to_choosen_group = choosen_group_send_assignment.nil? or choosen_group_send_assignment["grade"].nil?
          # se:
          # => aluno não enviou arquivos ao grupo atual E send_assignment do grupo não existe ou não foi avaliado
          # => novo grupo não tenha send_assignment ou não tenha sido avaliado
          if (student_can_be_removed_from_current_group and student_can_be_moved_to_choosen_group)
            unless new_group_assignment.nil?
              if current_group_participant.nil?
                GroupParticipant.create!(:group_assignment_id => new_group_assignment["id"], :user_id => student_id)
              elsif current_group_participant["group_assignment_id"] != new_group_assignment["id"]
                current_group_participant.update_attributes!(:group_assignment_id => new_group_assignment["id"])
              end
            else
              current_group_participant.delete unless current_group_participant.nil? 
            end
          end

        end
      end
    rescue Exception => error
      raise "#{error.message}"
    end
  end


end