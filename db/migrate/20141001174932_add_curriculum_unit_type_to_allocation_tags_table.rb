class AddCurriculumUnitTypeToAllocationTagsTable < ActiveRecord::Migration
  def change
    change_table :allocation_tags do |t|
      t.references :curriculum_unit_type
      t.foreign_key :curriculum_unit_types
    end
  end
end
