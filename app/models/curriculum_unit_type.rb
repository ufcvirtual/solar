class CurriculumUnitType < ActiveRecord::Base
  include Taggable

  has_many :curriculum_units
  has_many :offers,  -> { distinct }, through: :curriculum_units
  has_many :groups,  -> { distinct }, through: :offers
  has_many :courses, -> { distinct }, through: :offers

  def tool_name
    tn = case id
      when 3; "curriculum_units.index.course"
      when 7; "course.curriculum_units.index.course"
      when 4; "module.curriculum_units.index.course"
      else
       "curriculum_units.index.curriculum_unit"
    end
    I18n.t(tn)
  end

  def detailed_info
    { curriculum_unit_type: description }
  end

end
