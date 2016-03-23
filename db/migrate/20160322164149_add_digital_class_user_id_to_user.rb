class AddDigitalClassUserIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :digital_class_user_id, :integer
  end
end
