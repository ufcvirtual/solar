class ChangeAllocationEnrollment < ActiveRecord::Migration[5.0]
  def change
  	rename_column :allocations, :matricula, :enrollment
  end
end