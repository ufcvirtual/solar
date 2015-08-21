class CreateAssignmentWebconferences < ActiveRecord::Migration
  def change
    create_table :assignment_webconferences do |t|
      t.datetime :initial_time, null: false
      t.integer :duration, null: false
      t.boolean :is_recorded, default: false
      t.integer :sent_assignment_id, null: false
      t.string :title, null: false
      t.foreign_key :sent_assignments
      t.timestamps
    end

    add_index :assignment_webconferences, :sent_assignment_id
  end
end
