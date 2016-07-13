class ChangeAcademicAllocationUsers < ActiveRecord::Migration
  def up
    change_column :academic_allocation_users, :user_id, :integer, null: true
  end

  def down
    change_column :academic_allocation_users, :user_id, :integer, null: true
  end
end
