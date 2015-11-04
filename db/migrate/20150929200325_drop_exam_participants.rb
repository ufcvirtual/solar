class DropExamParticipants < ActiveRecord::Migration
  def up
    drop_table :exam_participants
  end

  def down
    create_table :exam_participants do |t|
      t.references :user, null: false
      t.references :exam, null: false
      t.foreign_key :users
      t.foreign_key :exams
      t.datetime :created_at
    end
  end
end
