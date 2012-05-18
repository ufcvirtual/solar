class CreateDiscussionPosts < ActiveRecord::Migration
  def self.up
    create_table "discussion_posts" do |t|
      t.integer  "user_id", :null => false
      t.integer  "discussion_id", :null => false
      t.integer  "profile_id", :null => false
      t.text     "content", :null => false

      t.timestamps # É importante nessa classe pela necessidade de registrarmos as datas de criação e alteração
    end

    execute <<-SQL
      ALTER TABLE discussion_posts ADD COLUMN father_id INTEGER NULL REFERENCES discussion_posts(id)
    SQL

    add_foreign_key(:discussion_posts, :users)
    add_foreign_key(:discussion_posts, :discussions)
    add_foreign_key(:discussion_posts, :profiles)
  end

  def self.down
    drop_table "discussion_posts"
  end
end
