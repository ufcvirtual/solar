class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
	t.integer :log_type
	t.string :message
	t.integer :userId
	t.integer :profileId
	t.integer :courseId
	t.integer :classId
      	t.timestamps
    end
  end

  def self.down
    drop_table :logs
  end
end
