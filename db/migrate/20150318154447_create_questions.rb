class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer :user_id, null: false
      t.foreign_key :users
      t.string :name, null: false
      t.text :enunciation, null: false
      t.integer :type_question, null: false
      t.boolean :status, default: false
      t.timestamps
    end
    add_index :questions, :user_id
  end
end
