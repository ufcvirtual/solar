class AddUninterruptedToExam < ActiveRecord::Migration[5.1]
  def change
    add_column :exams, :uninterrupted, :boolean, default: false
  end
end
