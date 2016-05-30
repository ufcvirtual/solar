class AddColumnGradeExamUsers < ActiveRecord::Migration
  def change
    add_column :exam_users, :grade, :float
  end
end
