class AddTimestampAllocations < ActiveRecord::Migration
  def change
    change_table :allocations do |t|
      t.timestamps
    end
    Allocation.update_all(created_at: Time.now, updated_at: Time.now)
  end
end
