class CreateFilesSends < ActiveRecord::Migration
  def self.up
    create_table :files_sends do |t|
      t.integer :send_assignment_id, :null => false
    end
  end

  def self.down
    drop_table :files_sends
  end
end
