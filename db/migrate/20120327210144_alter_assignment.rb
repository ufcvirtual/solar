class AlterAssignment < ActiveRecord::Migration[5.0]
  def self.up
    change_table :assignments do |t|
      t.integer :type_assignment, :null => false, :default => 1 # 1:individual / 2:grupo
    end
  end

  def self.down
    change_table :assignments do |t|
      t.remove :type_assignment
    end
  end
end
