class CreateDigitalClassDirectories < ActiveRecord::Migration
  def change
    create_table :digital_class_directories do |t|
      t.integer :directory_id, index: true, null: false
      t.integer :related_taggable_id, index: true, null: false
      t.timestamps
    end
  end
end
