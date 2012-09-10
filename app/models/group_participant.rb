class GroupParticipant < ActiveRecord::Base

  belongs_to :group_assignment
  belongs_to :user

  has_many :send_assignments
  
  # Retorna participantes do grupo
  def self.all_by_group_assignment(group_assignment_id)
    GroupParticipant.all(:select => "user_id, id", :conditions => ["group_assignment_id = #{group_assignment_id}", :order => "users.name", :includes => :user])
  end

  ##
  # Participantes do grupo do aluno e da atividade em questão
  ##
  def self.find_group_participants(activity_id, user_id)
    activity_type_assignment = Assignment.find(activity_id).type_assignment
    #acha o grupo de determinado aluno para determinado trabalho
    group_assignment = GroupAssignment.first(:conditions => ["group_participants.user_id = #{user_id} AND assignments.type_assignment = #{Group_Activity} AND assignments.id = #{activity_id}"], :include => [:assignment, :group_participants])
    if group_assignment.nil?
      return nil #se o aluno não estiver em nenhum grupo, retorna nulo
    else
      return(GroupParticipant.find_all_by_group_assignment_id(group_assignment.id)) #caso contrário, pesquisa os participantes do grupo encontrado
    end
  end

end
