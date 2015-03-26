class CreateQuestionImages < ActiveRecord::Migration
  def change
    create_table :question_images do |t|
      t.integer :question_id, null: false
      t.foreign_key :questions
      t.string :legend, limit: 100
      t.timestamps
    end
    add_attachment :question_images, :image
  end
end
