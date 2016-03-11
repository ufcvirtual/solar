class CreateLogNavigationSubs < ActiveRecord::Migration
  def change
    create_table :log_navigation_subs do |t|
      t.integer  :log_navigation_id
      t.integer  :support_material_files_id
      t.integer  :discussion_id	
      t.integer  :lesson_id
      t.integer  :lesson_notes_id
      t.integer  :assignments_id
      t.integer  :exams_id
      t.integer  :user_id
      t.integer  :chat_rooms_id
      t.integer  :student_id
      t.integer  :group_id
      t.integer  :webconferences_id	
      t.datetime :created_at
    end
  end
end
