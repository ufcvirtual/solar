class AddUserToBlacklist < ActiveRecord::Migration
  def up
    change_table :user_blacklist do |t|
      t.references :user, null: true
    end
  end

  def down
    remove_column :user_blacklist, :user_id
  end
end
