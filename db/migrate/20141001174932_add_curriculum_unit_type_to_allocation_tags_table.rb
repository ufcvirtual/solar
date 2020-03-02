class AddCurriculumUnitTypeToAllocationTagsTable < ActiveRecord::Migration[5.0]
  def change
    change_table :allocation_tags do |t|
      t.references :curriculum_unit_type
    end
    add_foreign_key :allocation_tags, :curriculum_unit_types
  end
end
