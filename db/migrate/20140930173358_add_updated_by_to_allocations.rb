class AddUpdatedByToAllocations < ActiveRecord::Migration
  def up
    add_column :allocations, :updated_by_user_id, :integer

    execute <<-SQL
      ALTER TABLE allocations ADD CONSTRAINT allocation_updated_by_user_id_fkey FOREIGN KEY (updated_by_user_id) REFERENCES users(id);
    SQL
  end

  def down
    remove_column :allocations, :updated_by_user_id
  end
end
