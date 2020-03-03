class AddMatriculaToAllocations < ActiveRecord::Migration[5.0]
  def change
    add_column :allocations, :matricula, :string
  end
end
