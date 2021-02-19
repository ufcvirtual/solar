class AddDigitalClassUserIdToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :digital_class_user_id, :integer
  end
end
