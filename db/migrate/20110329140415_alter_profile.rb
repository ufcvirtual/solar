class AlterProfile < ActiveRecord::Migration
  def self.up
    add_column :profiles, :student, :boolean, :default => false   # false - nao eh aluno; true - eh aluno
  end

  def self.down
    remove_column :profiles, :student
  end
end
