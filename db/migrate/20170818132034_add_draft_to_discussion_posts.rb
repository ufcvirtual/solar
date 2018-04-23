class AddDraftToDiscussionPosts < ActiveRecord::Migration[5.0]
  def change
    add_column :discussion_posts, :draft, :boolean, default: false
  end
end
