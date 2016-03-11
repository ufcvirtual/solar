class CreateLogNavigationsControls < ActiveRecord::Migration
  def change
    create_table :log_navigations_controls do |t|
      t.integer :user_id
      t.string :file, null: false
      t.boolean :status, default: false
      t.datetime :created_at
    end
  end
  def self.down
    drop_table :log_navigations_controls
  end
end
