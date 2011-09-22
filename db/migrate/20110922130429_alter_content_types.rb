class AlterContentTypes < ActiveRecord::Migration
  def self.up

    execute <<-SQL
      ALTER TABLE users ALTER COLUMN photo_content_type TYPE varchar(255);
      ALTER TABLE message_files ALTER COLUMN message_content_type TYPE varchar(255);
      ALTER TABLE assignment_files ALTER COLUMN attachment_content_type TYPE varchar(255);
      ALTER TABLE public_files ALTER COLUMN attachment_content_type TYPE varchar(255);
      ALTER TABLE comment_files ALTER COLUMN attachment_content_type TYPE varchar(255);
      ALTER TABLE discussion_post_files ALTER COLUMN attachment_content_type TYPE varchar(255);
    SQL

  end

  def self.down

    execute <<-SQL
      ALTER TABLE users ALTER COLUMN photo_content_type TYPE varchar(45);
      ALTER TABLE message_files ALTER COLUMN message_content_type TYPE varchar(45);
      ALTER TABLE assignment_files ALTER COLUMN attachment_content_type TYPE varchar(45);
      ALTER TABLE public_files ALTER COLUMN attachment_content_type TYPE varchar(45);
      ALTER TABLE comment_files ALTER COLUMN attachment_content_type TYPE varchar(45);
      ALTER TABLE discussion_post_files ALTER COLUMN attachment_content_type TYPE varchar(45);
    SQL

  end
end
