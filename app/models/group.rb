class Group < ActiveRecord::Base
  include Taggable

  default_scope order: 'groups.status, groups.code'

  belongs_to :offer

  has_one :curriculum_unit,      through: :offer
  has_one :course,               through: :offer
  has_one :semester,             through: :offer
  has_one :curriculum_unit_type, through: :curriculum_unit

  has_many :academic_allocations, through: :allocation_tag
  has_many :lesson_modules,       through: :academic_allocations, source: :academic_tool, source_type: 'LessonModule'
  has_many :assignments,          through: :academic_allocations, source: :academic_tool, source_type: 'Assignment'
  has_many :merges_as_main, class_name: 'Merge', foreign_key: 'main_group_id', dependent: :destroy
  has_many :merges_as_secundary, class_name: 'Merge', foreign_key: 'secundary_group_id', dependent: :destroy
  has_many :related_taggables

  after_create :set_default_lesson_module

  validates :code, :offer_id, presence: true

  validate :unique_code_on_offer, unless: "offer_id.nil? || code.nil? || !code_changed?"

  validates_length_of :code, maximum: 40

  def code_semester
    "#{code} - #{offer.semester.name}"
  end

  def set_default_lesson_module
    create_default_lesson_module(I18n.t(:general_of_group, scope: :lesson_modules))
  end

  # recupera os participantes com perfil de estudante
  def students_participants
    AllocationTag.get_participants(allocation_tag.id, { students: true })
  end

  def students_allocations
    Allocation.joins(:profile).where("cast( profiles.types & '#{Profile_Type_Student}' as boolean )")
      .where(status: Allocation_Activated, allocation_tag_id: allocation_tag.related).uniq(:user_id)
  end

  def any_lower_association?
    false
  end

  def as_label
    [offer.semester.name, code, offer.curriculum_unit.try(:name)].join('|')
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
