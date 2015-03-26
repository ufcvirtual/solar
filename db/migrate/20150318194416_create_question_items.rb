class CreateQuestionItems < ActiveRecord::Migration
  def change
    create_table :question_items do |t|
      t.integer :question_id, null: false
      t.foreign_key :questions
      t.text :description, null: false
      t.boolean :value, null: false
      t.timestamps
    end
    add_attachment :question_items, :item_image
  end
end
