class AlterTableCurriculumUnit < ActiveRecord::Migration
  def self.up
    rename_table :curriculum_unities, :curriculum_units
    rename_column :offers, :curriculum_unities_id, :curriculum_units_id
  end

  def self.down
    rename_table :curriculum_units, :curriculum_unities
    rename_column :offers, :curriculum_units_id, :curriculum_unities_id
  end
end