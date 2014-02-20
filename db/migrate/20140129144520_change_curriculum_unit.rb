class ChangeCurriculumUnit < ActiveRecord::Migration
  def up
    change_column :curriculum_units, :resume, :text, :null => true
    change_column :curriculum_units, :syllabus, :text, :null => true
    change_column :curriculum_units, :objectives, :text, :null => true
    add_column :curriculum_units, :credits, :float, :null => true
    add_column :curriculum_units, :working_hours, :integer, :null => true
  end

  def down
  	change_column :curriculum_units, :resume, :text, :null => false
  	change_column :curriculum_units, :syllabus, :text, :null => false
    change_column :curriculum_units, :objectives, :text, :null => false
    remove_column :curriculum_units, :credits
    remove_column :curriculum_units, :working_hours
  end
end
