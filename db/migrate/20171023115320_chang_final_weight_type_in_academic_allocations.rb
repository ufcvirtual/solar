class ChangFinalWeightTypeInAcademicAllocations < ActiveRecord::Migration[5.0]
  def up
  	change_column :academic_allocations, :final_weight, :decimal, default: 100, :precision => 5, :scale => 2
  end

  def down
  	change_column :academic_allocations, :final_weight, :integer, default: 100
  end
end
