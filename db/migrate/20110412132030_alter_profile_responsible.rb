class AlterProfileResponsible < ActiveRecord::Migration
  def self.up
    add_column :profiles, :class_responsible, :boolean, :default => false   # false - nao eh responsavel por turma; true - eh responsavel
  end

  def self.down
    remove_column :profiles, :class_responsible
  end
end
