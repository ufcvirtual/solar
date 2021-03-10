class AddLevelToDiscussionPost < ActiveRecord::Migration[5.1]
  def self.up
    add_column :discussion_posts, :level, :integer, :default => 1
  end

  def self.down
    remove_column :discussion_posts, :level
  end
end
