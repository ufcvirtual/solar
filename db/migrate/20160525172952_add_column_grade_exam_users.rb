class AddColumnGradeExamUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :exam_users, :grade, :float
  end
end
