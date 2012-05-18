class CreateFilesEnunciations < ActiveRecord::Migration
  def self.up
    create_table :files_enunciations do |t|
      t.integer :assignment_id, :null => false
    end

    add_foreign_key(:files_enunciations, :assignments)
  end

  def self.down
    drop_table :files_enunciations
  end
end
