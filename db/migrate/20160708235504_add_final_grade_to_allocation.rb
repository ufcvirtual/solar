class AddFinalGradeToAllocation < ActiveRecord::Migration
  def change
    add_column :allocations, :final_grade, :float
  end
end
