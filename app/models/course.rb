class Course < ActiveRecord::Base
  include Taggable

  default_scope order: "name"

  has_many :offers
  has_many :groups,               through: :offers, uniq: true
  has_many :curriculum_units,     through: :offers, uniq: true
  has_many :academic_allocations, through: :allocation_tag

  validates :name, :code, presence: true, uniqueness: true

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

  def info
    name
  end

end
