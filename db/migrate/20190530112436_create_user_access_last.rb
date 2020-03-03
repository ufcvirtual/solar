class CreateUserAccessLast < ActiveRecord::Migration[5.0]
  def change
    create_table :user_access_lasts do |t|
      t.integer :user_id
      t.integer :academic_allocation_id
      t.datetime :date_last_access
      t.foreign_key :users
      t.foreign_key :academic_allocations
    end
  end
end
