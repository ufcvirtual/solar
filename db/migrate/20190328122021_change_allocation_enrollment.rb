class ChangeAllocationEnrollment < ActiveRecord::Migration
  def change
  	rename_column :allocations, :matricula, :enrollment
  end
end