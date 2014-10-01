class ChangeCurriculumUnitAndCourseCodeLimit < ActiveRecord::Migration
  def up
    change_column :curriculum_units, :code, :string, limit: 40
    change_column :courses, :code, :string, limit: 40
  end
end
