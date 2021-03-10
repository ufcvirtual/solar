class AddCounterCacheToPosts < ActiveRecord::Migration[5.1]
  def change
    change_table :discussion_posts do |t|
      t.integer :children_count, default: 0, null: false
    end
  end
end
