class AlterTableCurriculumUnitAlterColumn < ActiveRecord::Migration
  def self.up
    change_column :curriculum_units, :objectives, :text
    change_column :curriculum_units, :prerequisites, :text
  end

  def self.down
    change_column :curriculum_units, :objectives, :string, :limit => 255
    change_column :curriculum_units, :prerequisites, :string, :limit => 255
  end
end
