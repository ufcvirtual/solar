class Allocation < ActiveRecord::Base

  GROUP_PERMISSION = OFFER_PERMISSION = true
  Pending, FinalExamPending, Approved, FinalExamApproved, Failed, FailedFrequency, Undefined = 0, 1, 2, 3, 4, 5, 6

  belongs_to :allocation_tag
  belongs_to :user
  belongs_to :profile
  belongs_to :updated_by, class_name: "User", foreign_key: :updated_by_user_id

  has_one :course,               -> { where('course_id is not null')}, through: :allocation_tag
  has_one :curriculum_unit,      -> { where('curriculum_unit_id is not null')}, through: :allocation_tag
  has_one :offer,                -> { where('offer_id is not null')}, through: :allocation_tag
  has_one :group,                -> { where('group_id is not null')}, through: :allocation_tag
  has_one :curriculum_unit_type, -> { where('curriculum_unit_type_id is not null')}, through: :allocation_tag
  belongs_to :origin_group, class_name: "Group", foreign_key: :origin_group_id

  has_many :chat_rooms
  has_many :chat_messages
  has_many :chat_participants

  validates :profile_id, :user_id, presence: true
  validate :valid_profile_in_allocation_tag?, if: '!allocation_tag_id.nil?'

  validates_uniqueness_of :profile_id, scope: [:user_id, :allocation_tag_id]

  after_save :update_digital_class_members, if: '(!new_record? && (status_changed? || profile_id_changed?))', on: :update
  after_save :update_digital_class_user_role, if: '(!new_record? && profile_id_changed?)', on: :update

  after_create :calculate_grade_and_hours

  validate :verify_profile, if: 'new_record? || profile_id_changed?'

  def can_change_group?
    not [Allocation_Cancelled, Allocation_Rejected].include?(status)
  end

  def merged_to
    Allocation.where(origin_group_id: group.try(:id)).map(&:allocation_tag).first.try(:info) unless group.blank?
  end

  def pending?
    status == Allocation_Pending # problema na delecao reativada
  end

  def pending!
    self.status = Allocation_Pending
    self.save!
  end

  def activate!
    self.status = Allocation_Activated
    self.save!

    calculate_working_hours unless allocation_tag.nil?
    calculate_final_grade unless allocation_tag.nil?

    send_email_to_enrolled_user
  end

  def reject!
    self.status = Allocation_Rejected
    self.save!
  end

  def deactivate!
    self.status = Allocation_Cancelled
    self.save!
  end

  ## verifica se oferta ou turma estao dentro do prazo
  def request_reactivate!
    al_offer = offer || group.offer
    raise 'off_period' unless Date.today.between?(al_offer.enrollment_period[0], al_offer.enrollment_period[1])
    self.status = Allocation_Pending_Reactivate
    self.save!
  end

  def cancel!
    pending? ? destroy : deactivate!
  end

  def groups
    allocation_tag.groups unless allocation_tag.nil?
  end

  def user_name
    user.name
  end

  def refer_to
    allocation_tag.try(:refer_to)
  end

  def status_color
    case status
      when Allocation_Pending_Reactivate, Allocation_Pending; "#FF6600"
      when Allocation_Activated; "#006600"
      when Allocation_Cancelled, Allocation_Rejected, Allocation_Merged; "#FF0000"
    end
  end

  def change_to_new_status(type, by_user)
    unless allocation_tag.nil?
      uc = allocation_tag.get_curriculum_unit
      raise 'not_allowed_user_uab' if (!uc.blank? && uc.curriculum_unit_type_id == 2 && self.status ==  Allocation_Activated && profile_id  == Profile.student_profile)
    end
    self.updated_by_user_id = by_user.try(:id)
    case type
      when :request_reactivate, Allocation_Pending_Reactivate
        raise CanCan::AccessDenied if user_id != by_user.id
        request_reactivate!
      when :cancel, :cancel_request, :cancel_profile_request
        # apenas quem pede matricula/perfil pode cancelar pedido / perfil de aluno e basico nao pode ser cancelado pela lista de perfis
        raise CanCan::AccessDenied if user_id != by_user.id or
          (type == :cancel_profile_request and (profile_id == Profile.student_profile or profile.has_type?(Profile_Type_Basic)))
        cancel!
      when :pending, Allocation_Pending; pending!
      when :reject, Allocation_Rejected; reject!
      when :accept, :activate, Allocation_Activated; activate!
      when :deactivate, Allocation_Cancelled; deactivate!
    end # case

    errors.empty?
  end

  def change_group(new_group, by_user)
    return self if group == new_group # sem mudanca de turma
    self.updated_by_user_id = by_user.try(:id)

    # cancela na turma anterior e cria uma nova alocação com a nova turma
    new_allocation = self.dup
    Allocation.transaction do
      cancel!

      new_allocation.allocation_tag_id = new_group.allocation_tag.id
      new_allocation.save!
    end

    new_allocation
  end

  def self.change_status_from(allocations, new_status, group: nil, by_user: nil)
    new_allocations = []
    allocations.each do |allocation|
      allocation = allocation.change_group(group, by_user) unless group.nil?
      new_allocations << allocation if allocation.change_to_new_status(new_status, by_user)
    end

    new_allocations
  end

  def self.enrollments(args = {})
    joins(allocation_tag: {group: :offer}, user: {}).where(query_for_enrollments(args), args).order("users.name")
  end

  def self.pending
    joins(:profile)
      .where("allocations.status IN (?, ?) AND NOT cast(profiles.types & ? as boolean)", Allocation_Pending, Allocation_Pending_Reactivate, Profile_Type_Student)
      .order("allocations.id")
  end

  def self.remove_unrelated_allocations(user, allocations)
    # recovers only responsible profiles allocations and remove all allocatios which user has no relation with
    allocations.where("cast(profiles.types & ? as boolean)", Profile_Type_Class_Responsible).select { |a| user.can?(:manage_profiles, Allocation, on: [a.allocation_tag_id]) }
  end

  def self.responsibles(allocation_tags_ids)
    includes(:profile, :user)
      .where("allocation_tag_id IN (?) AND allocations.status = ? AND (cast(profiles.types & ? as boolean))", allocation_tags_ids, Allocation_Activated, Profile_Type_Class_Responsible)
      .order("users.name")
  end

  def self.list_for_designates(allocation_tags_ids, is_admin = false)
    query = []
    query << (allocation_tags_ids.empty? ? "allocation_tag_id IS NULL" : "allocation_tag_id IN (?)")
    query << (!!is_admin ? "not(profiles.types & #{Profile_Type_Basic})::boolean" : "(profiles.types & #{Profile_Type_Class_Responsible})::boolean")

    joins(:profile, :user).where(query.join(' AND '), allocation_tags_ids)
  end

  def update_digital_class_members(ignore_changes=false)
    DigitalClass.update_members(self, ignore_changes)
  end

  def update_digital_class_user_role(professor_profiles=[], student_profiles=[], ignore_changes=false)
    DigitalClass.update_roles(self, professor_profiles, student_profiles, ignore_changes)
  end

  def calculate_final_grade(grade=nil)
    return true unless profile_id == Profile.student_profile && !allocation_tag.nil?

    calculate_parcial_grade
    calculate_final_exam_grade
  end

  def calculate_parcial_grade(manually = false)
    grades = parcial_grade_calculation(allocation_tag.related)
    pg = grades.first[:grade].to_f.round(2)

    update_attributes parcial_grade: pg, final_grade: (final_exam_grade.blank? ? pg : ((pg+final_exam_grade)/2).to_f.round(2))

    set_situation(manually)
  end

  def parcial_grade_calculation(ats)
    AcademicAllocation.find_by_sql <<-SQL
      WITH groups AS (
        SELECT group_participants.group_assignment_id AS group_id
        FROM group_participants
        WHERE user_id = #{user_id}
      )
      SELECT SUM(ac.grade) as grade
      FROM (
        SELECT (academic_allocations.final_weight::float/100)*SUM(COALESCE(acu.grade, acu_eq.max_grade, 0)*academic_allocations.weight)/SUM(academic_allocations.weight) AS grade
        FROM academic_allocations
        LEFT JOIN academic_allocation_users acu    ON acu.academic_allocation_id = academic_allocations.id AND (acu.user_id = #{user_id} OR acu.group_assignment_id IN (select group_id from groups))
        LEFT JOIN (
          SELECT max(grade) AS max_grade, equivalent.equivalent_academic_allocation_id
          FROM academic_allocation_users acu2
          LEFT JOIN academic_allocations equivalent ON acu2.academic_allocation_id = equivalent.id
          WHERE (acu2.user_id = #{user_id} OR acu2.group_assignment_id IN (select group_id from groups))
          AND equivalent.equivalent_academic_allocation_id IS NOT NULL
          GROUP BY equivalent_academic_allocation_id
        ) acu_eq ON academic_allocations.id = acu_eq.equivalent_academic_allocation_id
        WHERE
          academic_allocations.evaluative = true
          AND
          academic_allocations.allocation_tag_id IN (#{ats.join(',')})
          AND
          academic_allocations.equivalent_academic_allocation_id IS NULL
          AND
          academic_allocations.final_exam = false
        GROUP BY academic_allocations.final_weight
      ) ac;
    SQL
  end

  def calculate_final_exam_grade(manually = false)
    course = allocation_tag.get_course
    uc = allocation_tag.get_curriculum_unit
    ats = allocation_tag.related
    min_hours = (uc.try(:min_hours) || course.try(:min_hours))

    # if final_exam rules not defined or (have enough hours and everything is ok)
    if (course.passing_grade.blank? || ((parcial_grade < course.passing_grade && (course.min_grade_to_final_exam.blank? || course.min_grade_to_final_exam <= parcial_grade)) && (course.min_hours.blank? || uc.working_hours.blank? || (min_hours*0.01)*uc.working_hours <= working_hours)))
       afs = AcademicAllocation.find_by_sql <<-SQL
        WITH groups AS (
          SELECT group_participants.group_assignment_id AS group_id
          FROM group_participants
          WHERE user_id = #{user_id}
        )
        SELECT SUM(COALESCE(acu.grade, acu_eq.max_grade, 0))/COUNT(academic_allocations.id) AS grade
        FROM academic_allocations
        LEFT JOIN academic_allocation_users acu  ON acu.academic_allocation_id = academic_allocations.id AND (acu.user_id = #{user_id} OR acu.group_assignment_id IN (select group_id from groups))
        LEFT JOIN (
            SELECT max(grade) AS max_grade, equivalent.equivalent_academic_allocation_id
            FROM academic_allocation_users acu2
            LEFT JOIN academic_allocations equivalent ON acu2.academic_allocation_id = equivalent.id
            WHERE (acu2.user_id = #{user_id} OR acu2.group_assignment_id IN (select group_id from groups))
            AND equivalent.equivalent_academic_allocation_id IS NOT NULL
            GROUP BY equivalent_academic_allocation_id
          ) acu_eq ON academic_allocations.id = acu_eq.equivalent_academic_allocation_id
        WHERE
          academic_allocations.evaluative = true
          AND
          academic_allocations.allocation_tag_id IN (#{ats.join(',')})
          AND
          academic_allocations.final_exam = true
          AND
          academic_allocations.equivalent_academic_allocation_id IS NULL
          AND
          (acu.grade IS NOT NULL OR acu_eq.max_grade IS NOT NULL);
      SQL
      update_attributes final_exam_grade: ((afs.empty? || afs.first[:grade].blank?) ? nil : afs.first[:grade].to_f.round(2))
    elsif !final_exam_grade.blank?
      raise 'af'
      # update_attributes final_exam_grade: nil
    end

    update_attributes final_grade: (final_exam_grade.blank? ? parcial_grade : ((parcial_grade+final_exam_grade)/2).to_f.round(2))

    set_situation(manually)
  end

  def set_situation(manually = false)
    return true unless profile_id == Profile.student_profile && !allocation_tag.nil?

    course = allocation_tag.get_course
    uc = allocation_tag.get_curriculum_unit
    date = allocation_tag.situation_date
    min_hours = (uc.try(:min_hours) || course.try(:min_hours))

    if date.blank?
      last_date = AcademicTool.last_date(allocation_tag.id)
      allocation_tag.update_attributes situation_date: last_date[:date], situation_date_ac_id: last_date[:ac_id]
    end

    hours_defined = (!uc.working_hours.blank? && !min_hours.blank?)
    has_passing_grade = !course.passing_grade.blank?

    calculate_final_grade if parcial_grade.blank? && (manually || !final_grade.blank?)
    calculate_working_hours if (working_hours.blank? || working_hours == 0) && manually

    has_evaluative_activities = allocation_tag.academic_allocations.where(evaluative: true).any?
    has_frequency_activities = allocation_tag.academic_allocations.where(frequency: true).any?

    # if today should update situation or mannually update and has passing grade or hours defined
    if ((!date.nil? && Date.today >= date) || manually || allocation_tag.setted_situation) && (has_passing_grade || hours_defined) && (has_evaluative_activities || has_frequency_activities)
      # if hours defined and doesnt have enough hours
      if (hours_defined && (working_hours.blank? || ((min_hours*0.01)*uc.working_hours > working_hours))) && has_frequency_activities
        update_attributes grade_situation: FailedFrequency
      elsif has_passing_grade && has_evaluative_activities
        # if parcial grade is already enough
        if (!parcial_grade.blank? && parcial_grade >= course.passing_grade)
          update_attributes grade_situation: Approved
        # if parcial grade is not enough
        else
          # if there is a minimum grade to final exam and parcial grade still is not enough
          if (parcial_grade.blank? || (!course.min_grade_to_final_exam.blank? && course.min_grade_to_final_exam > parcial_grade))
            update_attributes grade_situation: Failed
          # if parcial grade is enough or there isnt a minimum grade to final exam
          else
            # if doesnt have a final exam grade
            if final_exam_grade.blank?
              if allocation_tag.academic_allocations.where(final_exam: true).any?
                update_attributes grade_situation: FinalExamPending
              else
                update_attributes grade_situation: Failed
              end
            # has a final exam grade
            else
              # if there is a minimum grade to final exam and it is not enough
              if !course.min_final_exam_grade.blank? && course.min_final_exam_grade > final_exam_grade
                update_attributes grade_situation: Failed
              # if there is no minimum grade to final exam OR there is and it is enough
              else
                # if there is a minimum passing grade after final exam and final grade is not enough
                if !course.final_exam_passing_grade.blank? && course.final_exam_passing_grade > final_grade
                  update_attributes grade_situation: Failed
                # final grade is enough
                elsif !course.final_exam_passing_grade.blank?
                  update_attributes grade_situation: FinalExamApproved
                # if there isnt a minimum passing grade after final exam and final grade is not enoguh
                elsif course.passing_grade > final_grade
                  update_attributes grade_situation: Failed
                # if there isnt a minimum passing grade after final exam and final grade is enoguh
                else
                  update_attributes grade_situation: FinalExamApproved
                end # !course.final_exam_passing_grade.blank? && course.final_exam_passing_grade > final_grade
              end # !course.min_final_exam_grade.blank? && course.min_final_exam_grade > final_exam_grade
            end # !course.min_grade_to_final_exam.blank? && course.min_grade_to_final_exam > parcial_grade
          end # min_grade_to_final_exam > parcial_grade
        end # parcial_grade >= course.passing_grade
      # if does not have evaluated activities or setted grade, but do have frequency configuration and activities, approved
      elsif (hours_defined && has_frequency_activities && (!has_evaluative_activities || !has_passing_grade))
        update_attributes grade_situation: Approved
      end # has_passing_grade
      allocation_tag.update_attributes setted_situation: true
    elsif (has_passing_grade || hours_defined)
      update_attributes grade_situation: Pending
      allocation_tag.update_attributes setted_situation: false
    else
      update_attributes grade_situation: Undefined
      allocation_tag.update_attributes setted_situation: false
    end
  end

  def calculate_working_hours
    if profile_id == Profile.student_profile && !allocation_tag.nil?
      update_attributes working_hours: Allocation.get_working_hours(user_id, allocation_tag)
    end
  end

  def self.get_working_hours(user_id, allocation_tag, tool=nil)
    # return 0 if allocation_tag.curriculum_unit.try(:working_hours).nil?
    query = tool.blank? ? '' : " AND academic_allocations.academic_tool_type=#{tool}"
    ats = allocation_tag.related.join(',')
    hours = AcademicAllocation.find_by_sql <<-SQL
      WITH groups AS (
        SELECT group_participants.group_assignment_id AS group_id
        FROM group_participants
        WHERE user_id = #{user_id}
      )
      SELECT SUM(COALESCE(acu.working_hours, acu_eq.max_working_hours, 0)) as working_hours
      FROM academic_allocations
      LEFT JOIN academic_allocation_users acu    ON acu.academic_allocation_id = academic_allocations.id AND (acu.user_id = #{user_id} OR acu.group_assignment_id IN (select group_id from groups))
      LEFT JOIN (
        SELECT max(working_hours) AS max_working_hours, equivalent.equivalent_academic_allocation_id
        FROM academic_allocation_users acu2
        LEFT JOIN academic_allocations equivalent ON acu2.academic_allocation_id = equivalent.id
        WHERE (acu2.user_id = #{user_id} OR acu2.group_assignment_id IN (select group_id from groups))
        AND equivalent.equivalent_academic_allocation_id IS NOT NULL
        GROUP BY equivalent_academic_allocation_id
      ) acu_eq ON academic_allocations.id = acu_eq.equivalent_academic_allocation_id
      WHERE
        academic_allocations.frequency = true
        AND
        academic_allocations.allocation_tag_id IN (#{ats})
        AND
        academic_allocations.equivalent_academic_allocation_id IS NULL
        AND
        academic_allocations.final_exam = false;
    SQL

    hours.first['working_hours'].round(2) rescue 0
  end

  def self.status_name(status)
    case status.to_i
    when 0; 'pending'
    when 1; 'final_exam_pending'
    when 2; 'approved'
    when 3; 'final_exam_approved'
    when 4; 'failed'
    when 5; 'failed_working_hours'
    when 6; 'undefined'
    end
  end

  def calculate_grade_and_hours
    if profile_id == Profile.student_profile && !allocation_tag.nil?
      calculate_working_hours
      calculate_final_grade
    end
  end

  private

    def verify_profile
      errors.add(:base, I18n.t('allocations.request.error.invalid_profile')) if profile.has_type?(Profile_Type_Basic) && !allocation_tag_id.nil?
      errors.add(:base, I18n.t('allocations.request.error.invalid_profile')) if profile.has_type?(Profile_Type_Admin) && !allocation_tag_id.nil?
    end

    def self.query_for_enrollments(args = {})
      query = ["profile_id = #{Profile.student_profile}", "allocation_tags.group_id IS NOT NULL"]

      if args.any?
        query << "groups.offer_id = :offer_id" if args[:offer_id].present?
        query << "groups.id IN (:group_id)" if args[:group_id].present?
        query << "allocations.status = :status" if args[:status].present?

        if args[:user_search].present?
          user_search = [args[:user_search].split(" ").compact.join("%"), "%"].join
          query << "lower(unaccent(users.name)) LIKE lower(unaccent('%#{user_search}'))"
        end
      end
      query.join(' AND ')
    end

    def valid_profile_in_allocation_tag?
      errors.add(:profile_id, I18n.t("allocations.error.student_in_group")) if profile_id == Profile.student_profile and refer_to != 'group'
    end

    def send_email_to_enrolled_user
      return if status != Allocation_Activated || refer_to != 'group' || profile_id != Profile.student_profile # envia email apenas para alunos sendo matriculados

      Thread.new do
        Notifier.enrollment_accepted(user.email, group.code_semester).deliver
      end
      true
    end

end
