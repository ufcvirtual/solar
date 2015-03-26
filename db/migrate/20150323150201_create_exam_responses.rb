class CreateExamResponses < ActiveRecord::Migration
  def change
    create_table :exam_responses do |t|
      t.integer :exam_user_id, null: false
      t.foreign_key :exam_users
      t.integer :question_item_id, null: false
      t.foreign_key :question_items
      t.boolean :value
      t.timestamps
    end
    add_index :exam_responses, :exam_user_id
    add_index :exam_responses, :question_item_id
  end
end
