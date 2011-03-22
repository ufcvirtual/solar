class AlterTableCurriculumUnits < ActiveRecord::Migration
  def self.up
    drop_table :curriculum_units

    create_table :curriculum_units do |t|
      t.references :curriculum_unit_types
      t.string   :name,     :null => false, :limit => 120
      t.string   :code,     :null => false, :limit => 10
      t.text     :description
      t.text     :syllabus
      t.float    :passing_grade
      t.timestamps
    end

    add_index :curriculum_units, ["code"],     :name => "index_curriculum_unit_on_code",   :unique => true
  end

  def self.down
    drop_table :curriculum_units

    create_table :curriculum_units do |t|
      t.string   :name,     :null => false, :limit => 120
      t.string   :code,     :null => false, :limit => 10
      t.text     :description
      t.text     :syllabus
      t.float    :passing_grade
      t.integer  :category, :null => false
      t.timestamps
    end

    add_index :curriculum_units, ["code"],     :name => "index_curriculum_unit_on_code",   :unique => true
    add_index :curriculum_units, ["category"], :name => "index_curriculum_unit_on_category"
  end
end
