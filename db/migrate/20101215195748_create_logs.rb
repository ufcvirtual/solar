class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
      t.string :log_type
      t.string :message
			t.string :user
			t.string :profile
			t.string :course
			t.string :classroom
      t.timestamps
    end
  end

  def self.down
    drop_table :logs
  end
end
