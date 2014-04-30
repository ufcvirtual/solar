class CreateLogActions < ActiveRecord::Migration
  def up
    create_table :log_actions do |t|
      t.integer :log_type, null: false

      t.references :user, null: false

      t.integer :tool_id # academic_allocation_id

      t.text :description
      t.string :ip

      t.datetime :created_at
    end

    add_index :log_actions, :user_id
    add_index :log_actions, :tool_id
  end

  def down
    remove_index :log_actions, :user_id
    remove_index :log_actions, :tool_id

    drop_table :log_actions
  end
end
