class AddChildrenCountCacheDrafsToPosts < ActiveRecord::Migration[5.1]
  def up
    change_table :discussion_posts do |t|
      t.integer :children_drafts_count, default: 0, null: false
    end
  end

  def down
    remove_column :discussion_posts, :children_drafts_count
  end
end
