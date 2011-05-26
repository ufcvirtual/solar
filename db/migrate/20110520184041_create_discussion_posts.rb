class CreateDiscussionPosts < ActiveRecord::Migration
  def self.up
    create_table :discussion_posts do |t|
      t.references :discussion
      t.references :user
      t.text :content
      t.timestamps # É importante nessa classe pela necessidade de registrarmos as datas de criação e alteração
    end

    execute <<-SQL
      ALTER TABLE discussion_posts ADD COLUMN father_id INTEGER NULL REFERENCES discussion_posts(id)
    SQL
  end

  def self.down
    drop_table :discussion_posts
  end
end
