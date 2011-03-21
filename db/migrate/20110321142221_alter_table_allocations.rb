class AlterTableAllocations < ActiveRecord::Migration
  def self.up

    drop_table :allocations

    create_table :allocations do |t|
      t.references :users
      t.references :allocation_tags
      t.references :profiles
      t.integer :status, :default => 0 # 0 - pendente; 1 - aceito; 2 - cancelado
      t.timestamps
    end

  end

  def self.down

    drop_table :allocations

    # existe uma migrate anterior q cria esta tabela
    create_table :allocations do |t|
      t.references :users
      t.references :groups
      t.references :profiles
      t.integer :status, :default => 0 # 0 - pendente; 1 - aceito; 2 - cancelado
      t.timestamps
    end

  end
end
