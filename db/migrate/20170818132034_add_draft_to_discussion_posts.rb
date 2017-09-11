class AddDraftToDiscussionPosts < ActiveRecord::Migration
  def change
    add_column :discussion_posts, :draft, :boolean, default: false
  end
end
