class CreateLessonAudios < ActiveRecord::Migration
  def change
    create_table :lesson_audios do |t|
      t.integer :lesson_id, null: false
      t.integer :count_text
      t.boolean :main
      t.foreign_key :lessons
      t.timestamps
    end
    add_attachment :lesson_audios, :audio
  end
end
