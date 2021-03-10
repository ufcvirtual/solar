class AddColumnGradeExamUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :exam_users, :grade, :float
  end
end
