class ChangeWeightDefault < ActiveRecord::Migration[5.1]
  def change
    change_column_default(:academic_allocations, :weight, 1)
  end
end
