class AddOtherSpecialNeedsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :other_special_needs, :string
  end
end
