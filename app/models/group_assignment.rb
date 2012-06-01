class GroupAssignment < ActiveRecord::Base

  belongs_to :assignment

  has_many :group_participants
  has_many :send_assignments

  validates :group_name, :presence => true

  validate :unique_group_name

  # Validação que verifica se o nome do grupo já existe naquela atividade
  def unique_group_name
    groups_with_same_name = GroupAssignment.find_all_by_assignment_id_and_group_name(assignment_id, group_name)
    errors.add(:group_name, I18n.t(:group_assignment_existing_name_error)) if (@new_record == true or group_name_changed?) and groups_with_same_name.size > 0
  end
 
  #retorna atividades de grupo de acordo com a turma
  def self.all_by_group_id(group_id)
    ActiveRecord::Base.connection.select_all <<SQL
    SELECT t1.id,
           t1.name,
           t1.enunciation,
           t3.start_date,
           t3.end_date
      FROM assignments     AS t1
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN schedules       AS t3 ON t3.id = t1.schedule_id
     WHERE t1.type_assignment=2 and t2.group_id = #{group_id}
     ORDER BY t3.start_date;
SQL
  end

  #retorna participantes de um grupo de trabalho
  def self.all_by_group_assignment_id(group_assignment_id)
    ActiveRecord::Base.connection.select_all <<SQL
    SELECT t1.*, t2.name, t2.nick, t2.email, t2.photo_file_name
      FROM group_participants AS t1
      INNER JOIN users AS t2 ON t1.user_id = t2.id
    WHERE t1.group_assignment_id=#{group_assignment_id}
    ORDER BY t2.name;
SQL
  end

  ##
  # Retorna apenas os alunos, daquela atividade, que não estão em nenhum grupo
  ##
  def self.all_without_group(assignment_id)
    groups_assignments_ids = GroupAssignment.find_all_by_assignment_id(assignment_id).map(&:id)
    assignment_allocation_tag_id = Assignment.find(assignment_id).allocation_tag_id
    ids_students_of_class = Profile.students_of_class(assignment_allocation_tag_id).map(&:id)
    all_participants_all_groups = []
    for group_assignment_id in groups_assignments_ids
      all_participants_all_groups += GroupParticipant.find_all_by_group_assignment_id(group_assignment_id).map(&:user_id)
    end
    no_group_students = []
    for id_student in ids_students_of_class
      no_group_students << User.find(id_student) unless all_participants_all_groups.include?(id_student)
    end

    return no_group_students
  end

end