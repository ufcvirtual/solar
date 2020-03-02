class CurriculumUnitType < ActiveRecord::Base
  include Taggable
  include APILog

  has_many :curriculum_units
  has_many :offers,  -> { distinct }, through: :curriculum_units
  has_many :groups,  -> { distinct }, through: :offers
  has_many :courses, -> { distinct }, through: :offers

  def tool_name
    tn = case id
      when 3; "course"
      when 7; "course"
      when 4; "module"
      else
       "curriculum_unit"
     end
    I18n.t(tn, "curriculum_units.index")
  end

  def detailed_info
    { curriculum_unit_type: description }
  end

end
