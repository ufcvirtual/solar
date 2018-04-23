class CreateCurriculumUnits < ActiveRecord::Migration[5.0]
  def self.up
    create_table "curriculum_units" do |t|
      t.integer  "curriculum_unit_type_id"
      t.string   "name",                     :limit => 120, :null => false
      t.string   "code",                     :limit => 10,  :null => false
      t.text     "resume"
      t.text     "syllabus"
      t.float    "passing_grade"
      t.string   "objectives"
      t.string   "prerequisites"
    end

    add_index "curriculum_units", ["code"], :name => "index_curriculum_unit_on_code", :unique => true

    add_foreign_key :curriculum_units, :curriculum_unit_types
  end

  def self.down
    drop_table "curriculum_units"
  end
end
