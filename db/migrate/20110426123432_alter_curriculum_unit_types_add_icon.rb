class AlterCurriculumUnitTypesAddIcon < ActiveRecord::Migration
  def self.up
    change_table :curriculum_unit_types do |t|
      t.string :icon_name, :limit => 60, :default => 'icon_type_free_course.png'
    end
  end

  def self.down
    change_table :curriculum_unit_types do |t|
      t.remove :icon_name
    end
  end
end
