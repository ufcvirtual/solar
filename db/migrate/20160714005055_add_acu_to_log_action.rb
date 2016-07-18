class AddAcuToLogAction < ActiveRecord::Migration
  def change
    change_table :log_actions do |t|
        t.integer :academic_allocation_user_id, null: true
        t.foreign_key :academic_allocation_users
    end
  end
end
