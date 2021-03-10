class ChangeCurriculumUnitAndCourseCodeLimit < ActiveRecord::Migration[5.1]
  def up
    change_column :curriculum_units, :code, :string, limit: 40
    change_column :courses, :code, :string, limit: 40
  end
end
