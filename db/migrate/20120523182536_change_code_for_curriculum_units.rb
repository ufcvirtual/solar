class ChangeCodeForCurriculumUnits < ActiveRecord::Migration[5.0]
  def self.up
    change_column :curriculum_units, :code, :string, :limit => 10, :null => true
    change_column :curriculum_units, :objectives, :text, :null => false
    change_column :curriculum_units, :curriculum_unit_type_id, :integer, :null => false
    change_column :curriculum_units, :resume, :text, :null => false
    change_column :curriculum_units, :syllabus, :text, :null => false
  end

  def self.down
    change_column :curriculum_units, :code, :string,  :limit => 10, :null => false
    change_column :curriculum_units, :objectives, :text, :null => true
    change_column :curriculum_units, :curriculum_unit_type_id, :integer, :null => true
    change_column :curriculum_units, :resume, :text, :null => true
    change_column :curriculum_units, :syllabus, :text, :null => true
  end
end
