class Assignment < ActiveRecord::Base

  belongs_to :allocation_tag
  belongs_to :schedule

  has_one :group, :through => :allocation_tag

  has_many :allocations, :through => :allocation_tag
  has_many :assignment_enunciation_files
  has_many :send_assignments
  has_many :group_assignments
  has_many :group_participants, :through => :group_assignments

  before_save :define_end_evaluation_date

  validate :min_end_evaluation_date
  validate :verify_offer_date_range

  ##
  # Define o valor "default"
  ##
  def define_end_evaluation_date
    offer = AllocationTag.find(allocation_tag_id).group.offer
    self.end_evaluation_date = offer.end_date if (end_evaluation_date.blank? or end_evaluation_date.nil?)
  end

  ##
  # Verifica o valor mínimo permitido para o campo 
  ##
  def min_end_evaluation_date
    define_end_evaluation_date
    schedule = Schedule.find(schedule_id)
    if end_evaluation_date < schedule.end_date.to_date
      errors.add(:end_evaluation_date, I18n.t(:greater_than_or_equal_to, :scope => [:activerecord, :errors, :messages], :count => schedule.end_date.to_date))
    end
  end

  ##
  # Datas da atividade devem estar no intervalo de datas da oferta
  ##
  def verify_offer_date_range
    offer    = AllocationTag.find(allocation_tag_id).group.offer
    schedule = Schedule.find(schedule_id)
    if schedule.end_date > offer.end_date
      errors.add(:base, I18n.t(:final_date_smaller_than_offer, :scope => [:assignment, :notifications], :end_date_offer => offer.end_date.to_date))
    elsif schedule.start_date > offer.start_date
      errors.add(:base, I18n.t(:start_date_greater_than_offer, :scope => [:assignment, :notifications], :end_date_offer => offer.start_date.to_date))
    end
  end

  ##
  # Recupera situação do aluno na atividade
  ##
  def self.assignment_situation_of_student(assignment_id, student_id, group_id = nil)
    assignment = Assignment.find(assignment_id)
    student_group = (assignment.type_assignment == Group_Activity) ? (GroupAssignment.first(:include => [:group_participants], :conditions => ["group_participants.user_id = #{student_id} 
      AND group_assignments.assignment_id = #{assignment.id}"])) : nil unless student_id.nil?
    user_id = (assignment.type_assignment == Group_Activity) ? nil : student_id
    group_id = (student_group.nil? ? group_id : student_group.id) # se aluno estiver em grupo, recupera id
    send_assignment = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(assignment_id, user_id, group_id)

    if assignment.schedule.start_date > Date.current()
      situation = "not_started"  
    elsif (not send_assignment.nil? and  not send_assignment.grade.nil?)
      situation = "corrected"
    elsif assignment.type_assignment == Group_Activity and group_id.nil?
      situation = "without_group"
    elsif (not send_assignment.nil? and send_assignment.assignment_files.size > 0)
      situation = "sent"
    elsif (send_assignment.nil? or send_assignment.assignment_files.size == 0) and assignment.schedule.end_date > Date.current
      situation = "send"
    elsif (send_assignment.nil? or send_assignment.assignment_files.size == 0) and assignment.schedule.end_date < Date.current
      situation = "not_sent"
    else
      situation = "-"
    end

    return situation
  end

  def closed?
    self.schedule.end_date < Date.today
  end

  ##
  # Verifica se o usuário tem permissão a "tempo extra" na atividade em que está acessando
  ##
  def extra_time?(user_id)
    return (self.allocation_tag.is_user_class_responsible?(user_id) and self.closed?)
  end

  ##
  # Verifica se está no prazo de avaliação
  ##
  def on_evaluation_period?(user_id)
    define_end_evaluation_date if self.end_evaluation_date.nil?
    return ((Date.today <= self.end_evaluation_date) and self.assignment_in_time?(user_id))
  end

  ## Verifica período que o responsável pode alterar algo na atividade
  def assignment_in_time?(user_id)
    if self.allocation_tag.is_user_class_responsible?(user_id) # se responsável
      can_access_assignment = (self.closed? and self.extra_time?(user_id)) # verifica se possui tempo extra
    end
    return (verify_date_range(self.schedule.start_date, self.schedule.end_date, Time.now) or can_access_assignment)
  end

  ## Verifica se uma data esta em um intervalo de outras
  def verify_date_range(start_date, end_date, date)
    return date > start_date && date < end_date
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
    assignments = Assignment.all(:joins => [:allocation_tag, :schedule], :conditions => ["allocation_tags.group_id = #{group_id} AND assignments.type_assignment = #{type_assignment}"],
     :select => ["assignments.id", "schedule_id", "schedules.end_date", "name", "enunciation", "type_assignment"]) # atividades da turma do tipo escolhido
  
    assignments_grades, groups_ids, has_comments, situation = [], [], [], [] # informações da situação do aluno

    assignments.each_with_index do |assignment, idx|
      student_group = (assignment.type_assignment == Group_Activity) ? (GroupAssignment.first(:include => [:group_participants], :conditions => ["group_participants.user_id = #{student_id} 
        AND group_assignments.assignment_id = #{assignment.id}"])) : nil
      user_id = (assignment.type_assignment == Group_Activity) ? nil : student_id
      groups_ids[idx] = (student_group.nil? ? nil : student_group.id) # se aluno estiver em grupo, recupera id deste
      send_assignment = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(assignment.id, user_id, groups_ids[idx])
      assignments_grades[idx] = send_assignment.nil? ? nil : send_assignment.grade #se tiver send_assignment, tenta pegar nota
      has_comments[idx] = send_assignment.nil? ? nil :  (not send_assignment.assignment_comments.empty?) # verifica se há comentários para o aluno
      situation[idx] = Assignment.assignment_situation_of_student(assignment.id, student_id)
    end

    return {"assignments" => assignments, "groups_ids" => groups_ids, "assignments_grades" => assignments_grades, "has_comments" => has_comments, "situation" => situation}
  end

  def user_can_access_assignment(current_user_id, user_id, group_id = nil)
    profile_student   = Profile.select(:id).where("cast(types & '#{Profile_Type_Student}' as boolean)").first
    student_of_class  = !allocations.where(:profile_id => profile_student.id).where(:user_id => current_user_id).empty?
    class_responsible = allocation_tag.is_user_class_responsible?(current_user_id)
    can_access = (user_id.to_i == current_user_id)

    if type_assignment == Group_Activity
      group      = GroupAssignment.find_by_id_and_assignment_id(group_id, id)
      can_access = group.group_participants.map(&:user_id).include?(current_user_id) unless group.nil?
    end
    return (class_responsible or (student_of_class and can_access))
  end

  def students_without_groups
    students_in_class   = Assignment.list_students_by_allocations(self.allocation_tag_id).map(&:id)
    students_with_group = self.group_assignments.map(&:group_participants).flatten.map(&:user_id)
    students            = [students_in_class - students_with_group].flatten.compact.uniq
    return students.empty? ? [] : User.select('id, name').find(students)
  end

end
