class AddAcademicAllocationUserToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :discussion_posts, :academic_allocation_user_id, :integer
  end
end
