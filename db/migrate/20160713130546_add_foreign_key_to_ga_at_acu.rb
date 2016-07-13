class AddForeignKeyToGaAtAcu < ActiveRecord::Migration
  def change
    change_table :academic_allocation_users do |t|
        t.foreign_key :group_assignments
    end
  end
end
