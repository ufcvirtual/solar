class AddCorrectedToExam < ActiveRecord::Migration
  def change
    add_column :exams, :corrected, :boolean, default: false, null: false
  end
end
