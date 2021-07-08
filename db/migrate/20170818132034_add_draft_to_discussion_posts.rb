class AddDraftToDiscussionPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :discussion_posts, :draft, :boolean, default: false
  end
end
