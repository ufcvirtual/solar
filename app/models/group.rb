class Group < ActiveRecord::Base
  include Taggable

  default_scope order: "groups.code"

  belongs_to :offer

  has_one :curriculum_unit, through: :offer
  has_one :course,          through: :offer
  has_one :semester,          through: :offer

  has_many :academic_allocations, through: :allocation_tag
  has_many :lesson_modules,       through: :academic_allocations, source: :academic_tool, source_type: "LessonModule"
  has_many :assignments,          through: :academic_allocations, source: :academic_tool, source_type: "Assignment"

  after_create :set_default_lesson_module

  validates :code, :offer_id, presence: true

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

  def self.find_all_by_offer_id_and_user_id(offer_id, user_id)
    Group.joins(offer: :semester).where(
      groups: {
        id: User.find(user_id).groups(nil, Allocation_Activated).map(&:id), offer_id: offer_id
      } ).select("DISTINCT groups.id, semesters.*, groups.*").order('semesters.name DESC, groups.code ASC')
  end

  def has_any_lower_association?
    false
  end

  def as_label
    [offer.semester.name, code, offer.curriculum_unit.try(:name)].join("|")
  end

  def association_ids
    result = Offer.select("offers.id AS offer_id, t1.id AS course_id, t2.id AS curriculum_unit_id")
      .joins("LEFT JOIN courses AS t1 ON t1.id = offers.course_id")
      .joins("LEFT JOIN curriculum_units AS t2 ON t2.id = offers.curriculum_unit_id")
      .where(offers: {id: offer_id}).first

    {offer_id: offer_id, course_id: result['course_id'], curriculum_unit_id: result['curriculum_unit_id']}
  end

  def detailed_info
    {
      curriculum_unit_type: offer.curriculum_unit_type.try(:description),
      course: offer.course.try(:name),
      curriculum_unit: offer.curriculum_unit.try(:name),
      semester: offer.semester.name,
      group: code
    }
  end

  def responsibles
    allocation_tags_ids = self.allocation_tag.related({all: false, upper: true})

    Allocation.joins(:profile, :user)
      .where(status: Allocation_Activated, allocation_tag_id: allocation_tags_ids)
      .where("cast( profiles.types & '#{Profile_Type_Class_Responsible.to_s(2)}' as boolean)")
      .select("users.name, profiles.name AS profile_name")
      .uniq
  end

end
