class AddUniqueRestrictionAllocations < ActiveRecord::Migration
  def up
    execute "ALTER TABLE allocations ADD CONSTRAINT allocations_unique_ids UNIQUE (user_id, allocation_tag_id, profile_id)"
  end

  def down
    execute "ALTER TABLE allocations DROP CONSTRAINT allocations_unique_ids"
  end
end
