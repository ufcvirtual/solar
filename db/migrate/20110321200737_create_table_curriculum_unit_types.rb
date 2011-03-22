class CreateTableCurriculumUnitTypes < ActiveRecord::Migration
  def self.up
    create_table :curriculum_unit_types do |t|
      t.string :description, :null => false, :limit => 50
      t.boolean :allows_enrollment, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :curriculum_unit_types
  end
end
