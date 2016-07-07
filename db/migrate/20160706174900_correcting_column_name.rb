class CorrectingColumnName < ActiveRecord::Migration
  def change
    rename_column :academic_allocations, :weigth, :weight
  end
end
