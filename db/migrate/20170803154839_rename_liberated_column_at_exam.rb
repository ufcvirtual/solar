class RenameLiberatedColumnAtExam < ActiveRecord::Migration
  def change
    rename_column :exams, :liberated_date, :result_release
  end
end
