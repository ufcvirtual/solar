class AlterTableCurriculumUnitsAddColumns < ActiveRecord::Migration
  def self.up
    change_table :curriculum_units do |t|
      t.string :objectives
      t.string :prerequisites
      t.rename :description, :resume
    end
  end

  def self.down
    change_table :curriculum_units do |t|
      t.remove :objectives
      t.remove :prerequisites
      t.rename :resume, :description
    end
  end
end
