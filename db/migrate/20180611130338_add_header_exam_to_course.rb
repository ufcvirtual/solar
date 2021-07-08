class AddHeaderExamToCourse < ActiveRecord::Migration[5.1]
  def up
    add_column :courses, :has_exam_header, :boolean, default: false, null: false
    add_column :courses, :header_exam, :text
  end

  def down
    remove_column :courses, :header_exam
    remove_column :courses, :has_exam_header
  end
end
