class AddAcademicAllocationUserToPosts < ActiveRecord::Migration
  def change
    add_column :discussion_posts, :academic_allocation_user_id, :integer
  end
end
