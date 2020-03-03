class AddCorrectedToExam < ActiveRecord::Migration[5.0]
  def change
    add_column :exams, :corrected, :boolean, default: false, null: false
  end
end
