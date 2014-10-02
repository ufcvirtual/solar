class Course < ActiveRecord::Base
  include Taggable

  default_scope order: "name"

  has_many :offers
  has_many :groups,               through: :offers, uniq: true
  has_many :curriculum_units,     through: :offers, uniq: true
  has_many :academic_allocations, through: :allocation_tag

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, if: "edx_course.nil?"
  validate :unique_name, unless: "edx_course.nil? or courses_names.nil?"

  validates_length_of :code, maximum: 40

  attr_accessor :edx_course, :courses_names

  def has_any_lower_association?
    self.offers.count > 0
  end

  def lower_associated_objects
    offers
  end

  def code_name
    [code, name].join(' - ')
  end

  def self.all_associated_with_curriculum_unit_by_name(type = 3)
    Course.where(name: CurriculumUnit.find_all_by_curriculum_unit_type_id(type).map(&:name))
  end

  def detailed_info
    {course: name}
  end

  def unique_name
    if courses_names.include?(name)
      errors.add(:name, I18n.t("edx.errors.existing_name")) 
    else
      codes = courses_names.collect{|name| name.slice(0..2).upcase}
      errors.add(:name, I18n.t("edx.errors.existing_code")) if codes.include?(name.slice(0..2).upcase)
    end
  end

  def curriculum_unit_types
    curriculum_units.map(&:curriculum_unit_type).uniq
  end

end
