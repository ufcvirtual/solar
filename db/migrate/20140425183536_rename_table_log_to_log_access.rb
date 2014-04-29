class RenameTableLogToLogAccess < ActiveRecord::Migration
  def up
    rename_table :logs, :log_accesses

    change_table :log_accesses do |t|
      t.remove :description, :course_id, :curriculum_unit_id, :group_id, :session_id

      t.references :allocation_tag
      t.foreign_key :allocation_tags

      t.string :ip
    end
  end

  def down
    rename_table :log_accesses, :logs

    change_table :logs do |t|
      t.string :description
      t.integer :course_id
      t.integer :curriculum_unit_id
      t.integer :group_id
      t.string :session_id

      t.remove :allocation_tag_id, :ip
    end

  end
end
