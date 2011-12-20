module MysolarHelper

  def load_curriculum_unit_data
    CurriculumUnit.find_default_by_user_id(current_user.id)
  end

end
