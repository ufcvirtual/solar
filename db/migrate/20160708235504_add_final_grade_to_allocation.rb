class AddFinalGradeToAllocation < ActiveRecord::Migration[5.0]
  def change
    add_column :allocations, :final_grade, :float
  end
end
