class Group < ActiveRecord::Base
  include Taggable

  belongs_to :offer

  has_one :curriculum_unit, through: :offer
  has_one :course,          through: :offer

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

  def self.find_all_by_curriculum_unit_id_and_user_id(curriculum_unit_id, user_id)
    Group.joins(offer: [:semester]).where(
      offers: {curriculum_unit_id: curriculum_unit_id},
      groups: {id: User.find(user_id).groups}).order('semesters.name DESC, groups.code ASC')
  end

  def has_any_lower_association?
    false
  end

  def as_label
    [offer.semester.name, code, offer.curriculum_unit.try(:name)].join("|")
  end

  def info
    [offer.course.try(:name), offer.curriculum_unit.try(:name), offer.semester.name, code].compact.join(" - ")
  end

end
