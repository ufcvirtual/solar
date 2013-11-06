class CreateCurriculumUnitTypes < ActiveRecord::Migration
  def self.up
    create_table "curriculum_unit_types" do |t|
      t.string   "description",       :limit => 50, :null => false
      t.boolean  "allows_enrollment", :default => true
      t.string   "icon_name", :limit => 60, :default => "icon_type_free_course.png"
    end
  end

  def self.down
    drop_table "curriculum_unit_types"
  end
end
