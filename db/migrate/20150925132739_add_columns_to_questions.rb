class AddColumnsToQuestions < ActiveRecord::Migration
  def up
    add_column :questions, :updated_by_user_id, :integer
    add_index :questions, :updated_by_user_id
    add_column :questions, :privacy, :boolean, default: false
    # remove_column :questions, :score

    add_column :question_items, :comment, :text
    add_column :question_items, :img_alt, :string

    add_column :question_images, :img_alt, :string, null: false

    add_column :exam_responses, :duration, :integer

    add_column :exams, :attempts_correction, :integer, default: 0
    add_column :exams, :block_content, :boolean, default: false

    change_column :question_items, :value, :boolean, default: false

    change_column :exams, :auto_correction, :boolean, default: true
  end

  def down
    remove_column :questions, :updated_by_user_id
    remove_column :questions, :privacy
    add_column :questions, :score, :float

    remove_column :question_items, :comment
    remove_column :question_items, :img_alt

    remove_column :question_images, :img_alt

    remove_column :exam_responses, :duration

    remove_column :exams, :attempts_correction
    remove_column :exams, :block_content
  end
end
