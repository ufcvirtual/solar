class AlterFatheridToParentid < ActiveRecord::Migration
  def self.up

    # menus
    execute <<-SQL
      ALTER TABLE menus RENAME COLUMN father_id TO parent_id;
      ALTER TABLE menus DROP CONSTRAINT menus_father_id_fkey;
      ALTER TABLE menus ADD CONSTRAINT menus_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES menus(id);
    SQL

    # discussion posts
    execute <<-SQL
      ALTER TABLE discussion_posts RENAME COLUMN father_id TO parent_id;
      ALTER TABLE discussion_posts DROP CONSTRAINT discussion_posts_father_id_fkey;
      ALTER TABLE discussion_posts ADD CONSTRAINT discussion_posts_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES discussion_posts(id);
    SQL

  end

  def self.down

    # menus
    execute <<-SQL
      ALTER TABLE menus RENAME COLUMN parent_id TO father_id;
      ALTER TABLE menus DROP CONSTRAINT menus_parent_id_fkey;
      ALTER TABLE menus ADD CONSTRAINT menus_father_id_fkey FOREIGN KEY (father_id) REFERENCES menus(id);
    SQL

    # discussion posts
    execute <<-SQL
      ALTER TABLE discussion_posts RENAME COLUMN parent_id TO father_id;
      ALTER TABLE discussion_posts DROP CONSTRAINT discussion_posts_parent_id_fkey;
      ALTER TABLE discussion_posts ADD CONSTRAINT discussion_posts_father_id_fkey FOREIGN KEY (father_id) REFERENCES discussion_posts(id);
    SQL

  end
end
