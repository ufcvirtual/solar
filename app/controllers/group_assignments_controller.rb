include GroupAssignmentHelper

class GroupAssignmentsController < ApplicationController

  before_filter :prepare_for_group_selection #, :only => [:list]
  before_filter :user_related_to_assignment?, :except => [:index]
  before_filter :can_import?, :only => [:import_groups_page, :import_groups]
  load_and_authorize_resource

  # lista trabalhos em grupo
  def index
    #authorize! :list, Portfolio
    group_id = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id

    #traz apenas os trabalhos de grupo dessa turma
    @assignments = GroupAssignment.all_by_group_id(group_id)
  end

  ##
  # Edita o grupo
  ##
  def update

    begin
      GroupAssignment.transaction do
        # criação/edição de grupos
        params['groups'].each { |group|
          group_id = group[1]['group_id']
          group_participants_ids = (group[1]['student_ids']).collect{|participant| participant[1].to_i} unless group[1]['student_ids'].nil?
          # se não forem alunos sem grupo
          unless group_id.nil?
            group_name = group[1]['group_name']['0']
            # novo grupo
            if group_id == '0'
              group_assignment = GroupAssignment.create!(:assignment_id => params[:assignment_id], :group_name => group_name)
            # grupo já existente
            else
              group_assignment = GroupAssignment.find(group_id)
              group_assignment.update_attributes!(:group_name => group_name)
            end
          end
          change_students_group(group_assignment, group_participants_ids, params[:assignment_id])
        }

        # deleção de grupos
        unless params['deleted_groups_divs_ids'].blank?
          params['deleted_groups_divs_ids'].each{ |deleted_group| 
            delete_group(deleted_group.tr('_', ' ').split[1])
          }
        end

        @assignment = Assignment.find(params[:assignment_id])

        respond_to do |format|
          format.html { render 'assignment_div', :layout => false }
        end
      end
    rescue Exception => error
      render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
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

private
  
  ##
  # Método que exclui grupos
  ##
  def delete_group(group_id)
    group_assignment = GroupAssignment.find(group_id)
    if SendAssignment.find_all_by_group_assignment_id(group_assignment.id).empty?
      participants = group_participants(group_assignment.id)
      participants.each{|participant| GroupParticipant.find(participant["id"]).destroy}
      GroupAssignment.find(group_assignment.id).destroy
    end
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
          
          group_participant = GroupParticipant.includes(:group_assignment).where("group_participants.user_id = ? AND group_assignments.assignment_id = ?",
                                                                                 student_id, assignment_id).first
          unless group_assignment.nil?
            if group_participant.nil?
              GroupParticipant.create!(:group_assignment_id => group_assignment.id, :user_id => student_id)
            elsif group_participant.group_assignment_id != group_assignment.id
              student_sent_files_to_other_group = !SendAssignment.where("send_assignments.user_id = ? AND send_assignments.group_assignment_id != ? AND 
                                                  send_assignments.assignment_id = ?", student_id, group_assignment.id, assignment_id).empty?
              group_participant.update_attributes!(:group_assignment_id => group_assignment.id) unless student_sent_files_to_other_group
            end
          else
            student_sent_files_to_some_group = !SendAssignment.where("send_assignments.user_id = ? AND send_assignments.assignment_id = ?", 
                                                                      student_id, assignment_id).empty?
            group_participant.delete unless student_sent_files_to_some_group or group_participant.nil? 
          end

        }
      end
    rescue Exception => error
      raise "#{error.message}"
    end
  end

end