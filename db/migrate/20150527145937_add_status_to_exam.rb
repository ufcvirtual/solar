class AddStatusToExam < ActiveRecord::Migration
  def change
    add_column :exams, :status, :boolean, null: false, default: false
  end
end
