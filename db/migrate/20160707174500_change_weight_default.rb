class ChangeWeightDefault < ActiveRecord::Migration
  def change
    change_column_default(:academic_allocations, :weight, 1)
  end
end
