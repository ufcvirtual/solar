class AddFileToBibliography < ActiveRecord::Migration
  def self.up
    add_attachment :bibliographies, :attachment
    change_column :bibliographies, :title, :text, null: true
  end

  def self.down
    remove_attachment :bibliographies, :attachment
    change_column :bibliographies, :title, :text, null: false
  end
end
