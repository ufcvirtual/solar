class GroupAssignment < ActiveRecord::Base

  belongs_to :assignment
  has_one :send_assignment, :dependent => :destroy
  has_many :group_participants, :dependent => :destroy

  validates :group_name, :presence => true, :length => { :maximum => 20 }
  validate :unique_group_name

  ##
  # Validação que verifica se o nome do grupo já existe naquela atividade
  ##
  def unique_group_name
    groups_with_same_name = GroupAssignment.find_all_by_assignment_id_and_group_name(assignment_id, group_name)
    errors.add(:group_name, I18n.t(:existing_name_error, :scope => [:assignment, :group_assignments])) if (@new_record == true or group_name_changed?) and groups_with_same_name.size > 0
  end
 
  #retorna atividades de grupo de acordo com a turma
  def self.all_by_group_id(group_id)
    Assignment.all(:conditions => ["type_assignment = #{Group_Activity} AND allocation_tags.group_id = #{group_id}"], :include => [:allocation_tag, :schedule, :group_assignments], :order => "schedules.start_date", :select => ["id, name, enunciation, schedule_id"])
  end

  ##
  # Retorna apenas os alunos, daquela atividade, que não estão em nenhum grupo
  ##
  def self.students_without_groups(assignment_id)
    groups_assignments_ids = GroupAssignment.find_all_by_assignment_id(assignment_id).map(&:id)
    assignment_allocation_tag_id = Assignment.find(assignment_id).allocation_tag_id
    ids_students_of_class = Assignment.list_students_by_allocations(assignment_allocation_tag_id).map(&:id)
    all_participants_all_groups = GroupParticipant.find_all_by_group_assignment_id(groups_assignments_ids).map(&:user_id)
    no_group_students = User.select("id, name").all(:conditions => ["id NOT IN (?) AND id IN (?)", all_participants_all_groups, ids_students_of_class])
    return all_participants_all_groups.empty? ? User.select("id, name").find(ids_students_of_class) : no_group_students
  end

##
# Caso grupo não tenha sido avaliado ou comentado ou enviado arquivos, pode ser excluído (para tudo isso, um "send_assignment" deve existir)
##
def self.can_remove_group?(group_id)
  send_assignment = SendAssignment.find_by_group_assignment_id(group_id)
  return (send_assignment.nil? or (send_assignment.assignment_files.empty? and send_assignment.grade.nil?))
end

end