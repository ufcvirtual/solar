class CreateLesson < ActiveRecord::Migration
  def self.up
    create_table :lessons do |t|
      t.references :allocation_tags # a que a aula esta vinculada
      t.references :users           # criador da aula
      t.string  :name,    :null => false
      t.string :description
      t.string  :address, :null => false
      t.integer :type,    :null => false                    # 1 - link; 2 - upload; 3 - editada
      t.boolean :privacy, :null => false, :default => true  # true - aula eh privada
      t.integer :order,   :null => false
      t.integer :status,  :null => false, :default => 0     # 0 - em teste; 1 - aprovada
      t.date    :start,   :null => false
      t.date    :end,     :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :lessons
  end
end
