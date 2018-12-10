class AddMatriculaToAllocations < ActiveRecord::Migration
  def change
    add_column :allocations, :matricula, :string
  end
end
