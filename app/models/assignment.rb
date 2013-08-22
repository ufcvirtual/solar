class Assignment < ActiveRecord::Base

  GROUP_PERMISSION = true

  #Relações extras
  has_many :allocation_tags, through: :academic_allocations
  #EXTRAS

  belongs_to :schedule #, :inverse_of => :assignments

  has_many :assignment_enunciation_files, dependent: :destroy
  has_many :allocations, through: :allocation_tags
  has_many :groups, through: :allocation_tags
  has_many :group_participants, through: :group_assignments # VERIFICAR

  #Associação polimórfica
  has_many :academic_allocations, as: :academic_tool
  has_many :sent_assignments, through: :academic_allocations
  has_many :group_assignments, through: :academic_allocations, dependent: :destroy
  #Associação polimórfica

  accepts_nested_attributes_for :schedule
  accepts_nested_attributes_for :assignment_enunciation_files, allow_destroy: true

  validates :name, :enunciation, :type_assignment, presence: true

  attr_accessible :schedule_attributes, :assignment_enunciation_files_attributes, :name, :enunciation, :type_assignment

  ## define uma data final de avaliacao caso nao esteja definida
  def define_end_evaluation_date(allocation_tag)
    self.end_evaluation_date = allocation_tag.group.offer.end_date if (end_evaluation_date.nil? or end_evaluation_date.blank? or (end_evaluation_date.to_date < schedule.end_date.to_date)) 
  end

  def student_group_by_student(student_id)
    #Operador ternário (if) anything ? (então) somenthing :(se não) other thing
    (self.type_assignment == Assignment_Type_Group) ? 
      (GroupAssignment.first(
      joins: :academic_allocation,
      include: :group_participants,
      conditions: ["group_participants.user_id = #{student_id} 
      AND academic_allocations.academic_tool_id = #{self.id}"])) : nil
  end

  def sent_assignment_by_user_id_or_group_assignment_id(allocation_tag_id, user_id, group_assignment_id)
    SentAssignment.joins(:academic_allocation).where(user_id: user_id, group_assignment_id: group_assignment_id, academic_allocations: {academic_tool_id: self.id, allocation_tag_id: allocation_tag_id}).first
  end   

  ## Recupera situação do aluno na atividade
  def situation_of_student(allocation_tag_id, student_id, group_assignment_id = nil)
    student_group = student_group_by_student(student_id) unless student_id.nil?
    user_id = (type_assignment == Assignment_Type_Group) ? nil : student_id
    group_id = (student_group.nil? ? group_assignment_id : student_group.id) # se aluno estiver em grupo, recupera id
    sent_assignment = sent_assignment_by_user_id_or_group_assignment_id(allocation_tag_id, user_id, group_assignment_id) 


    if schedule.start_date.to_date > Date.current()
      situation = "not_started"  
    elsif (not sent_assignment.nil? and  not sent_assignment.grade.nil?)
      situation = "corrected"
    elsif type_assignment == Assignment_Type_Group and group_id.nil?
      situation = "without_group"
    elsif (not sent_assignment.nil? and sent_assignment.assignment_files.size > 0)
      situation = "sent"
    elsif (sent_assignment.nil? or sent_assignment.assignment_files.size == 0) and schedule.end_date.to_date >= Date.current
      situation = "send"
    elsif (sent_assignment.nil? or sent_assignment.assignment_files.size == 0) and schedule.end_date.to_date < Date.current
      situation = "not_sent"
    else
      situation = "-"
    end

    return situation
  end

  def closed?
    schedule.end_date.to_date < Date.today
  end


  def extra_time?(allocation_tag, user_id)
    (allocation_tag.is_user_class_responsible?(user_id) and closed?)
  end


  def on_evaluation_period?(allocation_tag, user_id)
    define_end_evaluation_date(allocation_tag) if end_evaluation_date.nil? or end_evaluation_date.blank?
    ((Date.today <= end_evaluation_date.to_date) and assignment_in_time?(allocation_tag, user_id))
  end

  ## Verifica período que o responsável pode alterar algo na atividade
  def assignment_in_time?(allocation_tag, user_id)
    can_access_assignment = allocation_tag.is_user_class_responsible?(user_id) and (closed? and extra_time?(allocation_tag, user_id)) # verifica se possui tempo extra
    (verify_date_range(schedule.start_date, schedule.end_date, Date.current) or can_access_assignment)
  end

  ## Verifica se uma data esta em um intervalo de outras
  def verify_date_range(start_date, end_date, date)
    (date >= start_date.to_date and date <= end_date.to_date)
  end

  ##
  # Lista de alunos presentes nas turmas
  ##
  def self.list_students_by_allocations(allocations_ids)
    students_of_class_ids = Allocation.all(:include => [:allocation_tag, :user, :profile], :conditions => ["cast( profiles.types & '#{Profile_Type_Student}' as boolean) 
      AND allocations.status = #{Allocation_Activated} AND allocation_tags.group_id IS NOT NULL AND allocation_tags.id IN (#{allocations_ids})"]).map(&:user_id)
    students_of_class = User.select("name, id").find(students_of_class_ids)
    return students_of_class
  end

  ##
  # Recupera as atividades de determinado tipo de uma turma e informações da situação de determinado aluno nela
  ##
  def self.student_assignments_info(group_id, student_id, type_assignment)
    assignments = Assignment.all(
      joins: [{academic_allocations: :allocation_tag}, :schedule], 
      conditions: ["allocation_tags.group_id = #{group_id} AND assignments.type_assignment = #{type_assignment}"], 
      select: ["assignments.id", "schedule_id", "schedules.end_date", "name", "enunciation", "type_assignment"])
      # atividades da turma do tipo escolhido
  
    assignments_grades, group_assignments_ids, has_comments, situation = [], [], [], [] # informações da situação do aluno

    assignments.each_with_index do |assignment, idx|
      student_group = assignment.student_group_by_student(student_id)

      user_id = (assignment.type_assignment == Assignment_Type_Group) ? nil : student_id
      group_assignments_ids[idx] = (student_group.nil? ? nil : student_group.id) # se aluno estiver em grupo, recupera id deste
     
      allocation_tag_id = AllocationTag.find_by_group_id(group_id).id

      sent_assignment = assignment.sent_assignment_by_user_id_or_group_assignment_id(allocation_tag_id, user_id,group_assignments_ids[idx])

      assignments_grades[idx] = sent_assignment.nil? ? nil : sent_assignment.grade #se tiver sent_assignment, tenta pegar nota
      has_comments[idx] = sent_assignment.nil? ? nil :  (not sent_assignment.assignment_comments.empty?) # verifica se há comentários para o aluno
      situation[idx] = assignment.situation_of_student(allocation_tag_id, student_id)
    end

    return {"assignments" => assignments, "groups_ids" => group_assignments_ids, "assignments_grades" => assignments_grades, "has_comments" => has_comments, "situation" => situation}
  end

  def user_can_access_assignment(allocation_tag, current_user_id, user_id, group_id = nil)
    student_of_class  = !allocations.where(profile_id: Profile.student_profile).where(:user_id => current_user_id).empty?
    class_responsible = allocation_tag.is_user_class_responsible?(current_user_id)
    can_access = (user_id.to_i == current_user_id)

    if type_assignment == Assignment_Type_Group
      academic_allocation = AcademicAllocation.find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(allocation_tag.id,id, 'Assignment')
      group      = GroupAssignment.find_by_id_and_academic_allocation_id(group_id, academic_allocation.id)
      can_access = group.group_participants.map(&:user_id).include?(current_user_id) unless group.nil?
    end
    return (class_responsible or (student_of_class and can_access))
  end

  def students_without_groups(allocation_tag)
    academic_allocation  = AcademicAllocation.find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(allocation_tag.id,self.id, 'Assignment') 
    students_in_class   = Assignment.list_students_by_allocations(allocation_tag.id).map(&:id)
    students_with_group = academic_allocation.group_assignments.map(&:group_participants).flatten.map(&:user_id)
    students            = [students_in_class - students_with_group].flatten.compact.uniq
    return students.empty? ? [] : User.select('id, name').find(students)
  end

end
