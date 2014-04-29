class CreateLogActions < ActiveRecord::Migration
  def up
    create_table :log_actions do |t|
      t.integer :log_type, null: false

      t.references :user, null: false
      t.foreign_key :users

      t.integer :tool_id # academic_allocation_id

      t.string :description
      t.string :ip

      t.datetime :created_at
    end

    execute %{ ALTER TABLE log_actions ADD CONSTRAINT log_actions_academic_allocations_id_fkey FOREIGN KEY (tool_id) REFERENCES academic_allocations(id); }
  end

  def down
    drop_table :log_actions
  end
end
