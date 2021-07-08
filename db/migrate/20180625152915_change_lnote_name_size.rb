class ChangeLnoteNameSize < ActiveRecord::Migration[5.1]
  def change
    change_column :lesson_notes, :name, :string, limit: 150
  end
end
