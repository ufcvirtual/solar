class CorrectingColumnName < ActiveRecord::Migration[5.0]
  def change
    rename_column :academic_allocations, :weigth, :weight
  end
end
