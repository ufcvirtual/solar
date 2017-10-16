class AddAcuCommentsCounter < ActiveRecord::Migration
  def up
    add_column :academic_allocation_users, :comments_count, :integer, default: 0, null: false
    execute "UPDATE academic_allocation_users SET comments_count=(SELECT COUNT(comments.id) FROM comments WHERE comments.academic_allocation_user_id = academic_allocation_users.id);"
  end

  def down
    remove_column :academic_allocation_users, :comments_count
  end
end
