class RenameAssignmentComments < ActiveRecord::Migration
  def up
    rename_table :assignment_comments, :comments
    rename_column :comment_files, :assignment_comment_id, :comment_id

    remove_foreign_key :comment_files, :assignment_comments
    add_foreign_key :comment_files, :comments

    remove_foreign_key :comments, name: 'assignment_comments_academic_allocation_user_id_fk'
    add_foreign_key :comments, :academic_allocation_users
    remove_foreign_key :comments, name: 'assignment_comments_user_id_fk'
    add_foreign_key :comments, :users

    # rename_index :comments, 'assignment_comments_pkey', 'comments_pkey'
  end

  def down
    rename_table :comments, :assignment_comments
    rename_column :comment_files, :comment_id, :assignment_comment_id

    add_foreign_key :comment_files, :assignment_comments
    remove_foreign_key :comment_files, :comments
    remove_foreign_key :assignment_comments, name: 'comments_academic_allocation_user_id_fk'
    add_foreign_key :assignment_comments, :academic_allocation_users
    remove_foreign_key :assignment_comments, name: 'comments_user_id_fk'
    add_foreign_key :assignment_comments, :users

    rename_index :assignment_comments, 'comments_pkey', 'assignment_comments_pkey'
  end
end
