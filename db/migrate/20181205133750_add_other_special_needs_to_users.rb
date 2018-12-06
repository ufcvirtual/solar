class AddOtherSpecialNeedsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :other_special_needs, :string
  end
end
