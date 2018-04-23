class AddAcademicAllocationUserToPosts < ActiveRecord::Migration[5.0]
  def change
    add_column :discussion_posts, :academic_allocation_user_id, :integer
  end
end
