class GroupAssignment < ActiveRecord::Base

  belongs_to :academic_allocation, conditions: {academic_tool_type: 'Assignment'}

  has_one :sent_assignment, :dependent => :destroy

  has_many :group_participants, :dependent => :destroy

  validates :group_name, :presence => true, :length => { :maximum => 20 }
  validate :unique_group_name

  ##
  # Validação que verifica se o nome do grupo já existe naquela atividade
  ##
  def unique_group_name
    groups_with_same_name = GroupAssignment.find_all_by_academic_allocation_id_and_group_name(academic_allocation_id, group_name)
    errors.add(:group_name, I18n.t(:existing_name_error, :scope => [:assignment, :group_assignments])) if (@new_record == true or group_name_changed?) and groups_with_same_name.size > 0
  end
 
  #retorna atividades de grupo de acordo com a turma
  def self.all_by_group_id(group_id)
    Assignment.all(:conditions => ["type_assignment = #{Assignment_Type_Group}  
      AND allocation_tags.group_id = #{group_id}"], 
      include:  [:academic_allocations, :allocation_tags, :schedule, :group_assignments],
      order:"schedules.start_date",
      select: ["id, name, enunciation, schedule_id"])
  end

  ##
  # Caso grupo não tenha sido avaliado ou comentado ou enviado arquivos, pode ser excluído (para tudo isso, um "sent_assignment" deve existir)
  ##
  def self.can_remove_group?(group_id)
    sent_assignment = SentAssignment.find_by_group_assignment_id(group_id)
    return (sent_assignment.nil? or (sent_assignment.assignment_files.empty? and sent_assignment.grade.nil?))
  end

end