class ChangeWorkingHoursAllocationsType < ActiveRecord::Migration[5.0]
  def up
    change_column :allocations, :working_hours, :decimal, precision: 5, scale: 2
  end

  def down
    change_column :allocations, :working_hours, :integer
  end
end
