class CurriculumUnitType < ActiveRecord::Base
  include Taggable

  default_scope order: "description"

  has_many :curriculum_units
  has_many :offers,  through: :curriculum_units, uniq: true
  has_many :groups,  through: :offers, uniq: true
  has_many :courses, through: :offers, uniq: true
  
  def tool_name
    tool_name = case id
      when 3; "course"
      when 7; "course"
      when 4; "module"
      else
       "curriculum_unit"
     end
    I18n.t("curriculum_units.index.#{tool_name}")
  end

  def detailed_info
    { curriculum_unit_type: description }
  end

end


