class AddUninterruptedToExam < ActiveRecord::Migration
  def change
    add_column :exams, :uninterrupted, :boolean, default: false
  end
end
