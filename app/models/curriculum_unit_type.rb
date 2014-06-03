class CurriculumUnitType < ActiveRecord::Base
  has_many :curriculum_units
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
end


