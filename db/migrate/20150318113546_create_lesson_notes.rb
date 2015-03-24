class CreateLessonNotes < ActiveRecord::Migration
  def change
    create_table :lesson_notes do |t|
      t.string :name, limit: 50
      t.text :description, null: false
      t.integer :lesson_id, null: false
      t.foreign_key :lessons
      t.integer :user_id, null: false
      t.foreign_key :users
      t.timestamps
    end
    # execute "CREATE UNIQUE INDEX sav_group ON savs (sav_id, group_id);"
    add_index :lesson_notes, :lesson_id
    add_index :lesson_notes, :user_id
  end
end
