class CreateTableCurriculumUnit < ActiveRecord::Migration
  def self.up
    create_table :curriculum_unities do |t|
      t.string   :name,     :null => false
      t.string   :code,     :null => false
      t.text     :description
      t.text     :syllabus
      t.float    :passing_grade
      t.integer  :category, :null => false
      t.timestamps
    end

    add_index :curriculum_unities, ["code"],     :name => "index_curriculum_unit_on_code",   :unique => true
    add_index :curriculum_unities, ["category"], :name => "index_curriculum_unit_on_category"
  end

  def self.down
    drop_table :curriculum_unities
  end
end
