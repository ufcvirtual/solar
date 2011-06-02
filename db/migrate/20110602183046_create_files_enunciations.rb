class CreateFilesEnunciations < ActiveRecord::Migration
  def self.up
    create_table :files_enunciations do |t|
      t.integer :assignment_id, :null => false
    end
  end

  def self.down
    drop_table :files_enunciations
  end
end
