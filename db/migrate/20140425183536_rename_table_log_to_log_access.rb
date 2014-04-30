class RenameTableLogToLogAccess < ActiveRecord::Migration
  def up
    rename_table :logs, :log_accesses

    change_table :log_accesses do |t|
      t.remove :description, :course_id, :curriculum_unit_id, :group_id, :session_id

      t.references :allocation_tag

      t.string :ip
    end

    add_index :log_accesses, :user_id
    add_index :log_accesses, :allocation_tag_id

    ## quem era 2 vira um outro log (new_user)
    old_log = LogAccess.where(log_type: 2)
    old_log.each do |ol|
      LogAction.create(log_type: 4, user_id: ol.user_id, created_at: ol.created_at)
    end

    LogAccess.where(log_type: 3).update_all("log_type = 2") # 3 -> 2

  end

  def down
    remove_index :log_accesses, :user_id
    remove_index :log_accesses, :allocation_tag_id

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
