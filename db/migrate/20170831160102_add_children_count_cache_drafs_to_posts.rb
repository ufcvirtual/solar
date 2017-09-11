class AddChildrenCountCacheDrafsToPosts < ActiveRecord::Migration
    def change
    change_table :discussion_posts do |t|
      t.integer :children_drafts_count, default: 0, null: false
    end
  end
end
