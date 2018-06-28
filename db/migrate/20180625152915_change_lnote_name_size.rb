class ChangeLnoteNameSize < ActiveRecord::Migration
  def change
    change_column :lesson_notes, :name, :string, limit: 150
  end
end
