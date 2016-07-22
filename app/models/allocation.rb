class Allocation < ActiveRecord::Base

  GROUP_PERMISSION = OFFER_PERMISSION = true

  belongs_to :allocation_tag
  belongs_to :user
  belongs_to :profile
  belongs_to :updated_by, class_name: "User", foreign_key: :updated_by_user_id

  has_one :course,               through: :allocation_tag, conditions: ['course_id is not null']
  has_one :curriculum_unit,      through: :allocation_tag, conditions: ['curriculum_unit_id is not null']
  has_one :offer,                through: :allocation_tag, conditions: ['offer_id is not null']
  has_one :group,                through: :allocation_tag, conditions: ['group_id is not null']
  has_one :curriculum_unit_type, through: :allocation_tag, conditions: ['curriculum_unit_type_id is not null']

  has_many :chat_rooms
  has_many :chat_messages
  has_many :chat_participants

  validates :profile_id, :user_id, presence: true
  validate :valid_profile_in_allocation_tag?, if: '!allocation_tag_id.nil?'

  validates_uniqueness_of :profile_id, scope: [:user_id, :allocation_tag_id]

  after_save :update_digital_class_members, if: '(!new_record? && (status_changed? || profile_id_changed?))', on: :update
  after_save :update_digital_class_user_role, if: '(!new_record? && profile_id_changed?)', on: :update

  def can_change_group?
    not [Allocation_Cancelled, Allocation_Rejected].include?(status)
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

  def request_reactivate!
    ## verifica se oferta ou turma estao dentro do prazo

    al_offer = offer || group.offer
    return unless al_offer.enrollment_period.include?(Date.today)

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
      when Allocation_Cancelled, Allocation_Rejected; "#FF0000"
    end
  end

  def change_to_new_status(type, by_user)
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
    ats = allocation_tag.related
    grades = AcademicAllocation.find_by_sql <<-SQL
      WITH groups AS ( 
        SELECT group_participants.group_assignment_id AS group_id 
        FROM group_participants 
        WHERE user_id = #{user_id}
      )
      SELECT SUM(ac.grade) as grade
      FROM (
        SELECT  (academic_allocations.final_weight::float/100)*SUM(COALESCE(acu.grade, acu_eq.grade, 0)*academic_allocations.weight)/SUM(academic_allocations.weight) AS grade
        FROM academic_allocations
        LEFT JOIN academic_allocations equivalent  ON academic_allocations.id = equivalent.equivalent_academic_allocation_id
        LEFT JOIN academic_allocation_users acu    ON acu.academic_allocation_id = academic_allocations.id AND (acu.user_id = #{user_id} OR acu.group_assignment_id IN (select group_id from groups))
        LEFT JOIN academic_allocation_users acu_eq ON acu_eq.academic_allocation_id = equivalent.id  AND (acu_eq.user_id = #{user_id} OR acu_eq.group_assignment_id IN (select group_id from groups))
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

    afs = AcademicAllocation.find_by_sql <<-SQL
      WITH groups AS ( 
        SELECT group_participants.group_assignment_id AS group_id 
        FROM group_participants 
        WHERE user_id = #{user_id}
      )
      SELECT SUM(acu.grade)/COUNT(acu.id) AS grade
      FROM academic_allocations
      LEFT JOIN academic_allocation_users acu  ON acu.academic_allocation_id = academic_allocations.id AND (acu.user_id = #{user_id} OR acu.group_assignment_id IN (select group_id from groups))
      WHERE
        academic_allocations.evaluative = true
        AND
        academic_allocations.allocation_tag_id IN (#{ats.join(',')})
        AND
        academic_allocations.final_exam = true
        AND
        acu.grade IS NOT NULL;
    SQL

    update_attributes final_grade: ((afs.empty? || afs.first[:grade].blank?) ? grades.first[:grade] : (grades.first[:grade].to_f+afs.first[:grade].to_f)/2)
  end

  def get_working_hours
    Allocation.get_working_hours(user_id, allocation_tag)
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
      SELECT SUM(COALESCE(acu.working_hours, acu_eq.working_hours, 0)) as working_hours
      FROM academic_allocations
      LEFT JOIN academic_allocations equivalent  ON academic_allocations.id = equivalent.equivalent_academic_allocation_id
      LEFT JOIN academic_allocation_users acu    ON acu.academic_allocation_id = academic_allocations.id AND (acu.user_id = #{user_id} OR acu.group_assignment_id IN (select group_id from groups))
      LEFT JOIN academic_allocation_users acu_eq ON acu_eq.academic_allocation_id = equivalent.id AND (acu_eq.user_id = #{user_id} OR acu_eq.group_assignment_id IN (select group_id from groups))
      WHERE
        academic_allocations.frequency = true
        AND
        academic_allocations.allocation_tag_id IN (#{ats})
        AND
        academic_allocations.equivalent_academic_allocation_id IS NULL
        AND
        academic_allocations.final_exam = false;
    SQL

    hours.first['working_hours'].to_i rescue 0
  end

  private

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
