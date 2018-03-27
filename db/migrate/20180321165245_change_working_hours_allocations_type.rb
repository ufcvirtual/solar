class ChangeWorkingHoursAllocationsType < ActiveRecord::Migration
  def up
    change_column :allocations, :working_hours, :decimal, precision: 5, scale: 2
  end

  def down
    change_column :allocations, :working_hours, :integer
  end
end
