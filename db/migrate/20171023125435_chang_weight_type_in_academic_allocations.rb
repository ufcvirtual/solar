class ChangWeightTypeInAcademicAllocations < ActiveRecord::Migration[5.0]
  def up
  	change_column :academic_allocations, :weight, :decimal, default: 1, :precision => 5, :scale => 2
  end

  def down
  	change_column :academic_allocations, :weight, :integer, default: 1
  end
end
