class RemoveEndEvaluationDateFromAssignments < ActiveRecord::Migration[5.1]
  def up
    remove_column :assignments, :end_evaluation_date
  end

  def down
    add_column :assignments, :end_evaluation_date, :date
  end
end
