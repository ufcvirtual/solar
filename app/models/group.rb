class Group < ActiveRecord::Base
  include Taggable

  default_scope order: "groups.status, groups.code"

  belongs_to :offer

  has_one :curriculum_unit,      through: :offer
  has_one :course,               through: :offer
  has_one :semester,             through: :offer
  has_one :curriculum_unit_type, through: :curriculum_unit

  has_many :academic_allocations, through: :allocation_tag
  has_many :lesson_modules,       through: :academic_allocations, source: :academic_tool, source_type: "LessonModule"
  has_many :assignments,          through: :academic_allocations, source: :academic_tool, source_type: "Assignment"
  has_many :merges_as_main, class_name: "Merge", foreign_key: "main_group_id", dependent: :destroy
  has_many :merges_as_secundary, class_name: "Merge", foreign_key: "secundary_group_id", dependent: :destroy

  after_create :set_default_lesson_module

  validates :code, :offer_id, presence: true

  validate :unique_code_on_offer, unless: "offer_id.nil? or code.nil? or not(code_changed?)"

  validates_length_of :code, maximum: 40

  def code_semester
    "#{code} - #{offer.semester.name}"
  end

  def set_default_lesson_module
    create_default_lesson_module(I18n.t(:general_of_group, scope: :lesson_modules))
  end

  # recupera os participantes com perfil de estudante
  def students_participants
    allocations.joins(:profile).where("cast( profiles.types & '#{Profile_Type_Student}' as boolean)").where(status: Allocation_Activated).uniq
  end

  def has_any_lower_association?
    false
  end

  def as_label
    [offer.semester.name, code, offer.curriculum_unit.try(:name)].join("|")
  end

  def association_ids
    result = Offer.select("offers.id AS offer_id, t1.id AS course_id, t2.id AS curriculum_unit_id,  t3.id AS curriculum_unit_type_id")
      .joins("LEFT JOIN courses AS t1 ON t1.id = offers.course_id")
      .joins("LEFT JOIN curriculum_units AS t2 ON t2.id = offers.curriculum_unit_id")
      .joins("LEFT JOIN curriculum_unit_types AS t3 ON t3.id = t2.curriculum_unit_type_id")
      .where(offers: {id: offer_id}).first

    {offer_id: offer_id, course_id: result['course_id'], curriculum_unit_id: result['curriculum_unit_id'], curriculum_unit_type_id: result['curriculum_unit_type_id']}
  end

  def detailed_info
    {
      curriculum_unit_type: offer.curriculum_unit_type.try(:description),
      curriculum_unit_type_id: offer.curriculum_unit_type.try(:id),
      course: offer.course.try(:name),
      curriculum_unit: offer.curriculum_unit.try(:name),
      semester: offer.semester.name,
      group: code
    }
  end

  def responsibles
    allocation_tags_ids = self.allocation_tag.related({upper: true})

    Allocation.joins(:profile, :user)
      .where(status: Allocation_Activated, allocation_tag_id: allocation_tags_ids)
      .where("cast( profiles.types & '#{Profile_Type_Class_Responsible.to_s(2)}' as boolean)")
      .select("users.name, profiles.name AS profile_name")
      .uniq
  end

  def request_enrollment(user_id)
    result = {success: [], error: []}
    allocation = Allocation.where(user_id: user_id, allocation_tag_id: allocation_tag.id, profile_id: Profile.student_profile).first_or_initialize

    enroll_period = offer.enrollment_period
    if Time.now.between?(enroll_period.first, enroll_period.last) # verify enrollment period
      allocation.status = Allocation_Pending
      allocation.save
      result[:success] << allocation
    else
      allocation.errors.add(:base, I18n.t('allocations.request.error.enroll'))
      result[:error] << allocation
    end

    result
  end

  def self.find_all_by_offer_id_and_user_id(offer_id, user_id)
    Group.joins(offer: :semester).where(
      groups: {
        id: User.find(user_id).groups(nil, Allocation_Activated).map(&:id), offer_id: offer_id,
        status: true
      } ).select("DISTINCT groups.id, semesters.*, groups.*").order('semesters.name DESC, groups.code ASC')
  end

  ## triggers

  trigger.after(:update).of(:offer_id, :status) do
    <<-SQL
      UPDATE related_taggables
         SET group_status = NEW.status,
             offer_id = NEW.offer_id,
             offer_at_id = (SELECT id FROM allocation_tags WHERE offer_id = NEW.offer_id)
       WHERE group_id = OLD.id;
    SQL
  end

  private

    def unique_code_on_offer
      errors.add(:code, I18n.t(:taken, scope: [:activerecord, :errors, :messages])) if Group.where(offer_id: offer_id, code: code).any?
    end

end
