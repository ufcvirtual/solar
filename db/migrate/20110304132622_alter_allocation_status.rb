class AlterAllocationStatus < ActiveRecord::Migration
  def self.up
    remove_column :allocations, :status
    add_column :allocations, :status, :integer, :default => 0   # 0 - pendente; 1 - aceito; 2 - cancelado
  end

  def self.down
    remove_column :allocations, :status
    add_column :allocations, :status, :boolean, :default => true
  end
end
