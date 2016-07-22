class AddTimestampToAcu < ActiveRecord::Migration
  def change
    change_table :academic_allocation_users do |t|
        t.timestamps
    end
  end
end
