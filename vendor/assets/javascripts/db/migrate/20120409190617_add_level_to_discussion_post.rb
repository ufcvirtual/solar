class AddLevelToDiscussionPost < ActiveRecord::Migration
  def self.up
    add_column :discussion_posts, :level, :integer, :default => 1
  end

  def self.down
    remove_column :discussion_posts, :level
  end
end
