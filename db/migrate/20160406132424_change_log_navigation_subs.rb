class ChangeLogNavigationSubs < ActiveRecord::Migration
  def change
    change_table :log_navigation_subs do |t|
      t.rename :group_id, :group_assignment_id
      t.rename :assignments_id, :assignment_id
      t.rename :exams_id, :exam_id
      t.rename :chat_rooms_id, :chat_room_id
      t.rename :webconferences_id, :webconference_id
      t.rename :hist_chat_rooms_id, :hist_chat_room_id

      t.remove :support_material_files_id
      t.string :support_material_file

      t.remove :bibliographie_id
      t.string :bibliography
      
      t.boolean :webconference_record

      t.string :digital_class_lesson
      
      t.string :public_file_name

      t.remove :public_files_id
      t.boolean :public_area

      t.string :lesson

      t.remove :lesson_notes_id
      t.boolean :lesson_notes
    end
  end
end
