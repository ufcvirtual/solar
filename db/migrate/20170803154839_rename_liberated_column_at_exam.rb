class RenameLiberatedColumnAtExam < ActiveRecord::Migration[5.1]
  def change
    rename_column :exams, :liberated_date, :result_release
  end
end
