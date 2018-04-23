class ChangeDraftPost < ActiveRecord::Migration[5.0]
  def change
  	change_column :discussion_posts, :draft, :boolean, default: false, null: false
  	Post.where(draft: nil).update_all draft: false
  end
end
