class CreateUserContacts < ActiveRecord::Migration
  def self.up
    create_table "user_contacts", :id => false do |t|
    end

    execute <<-SQL
      ALTER TABLE user_contacts ADD COLUMN user_id INTEGER NOT NULL REFERENCES users(id);
      ALTER TABLE user_contacts ADD COLUMN user_related_id INTEGER NOT NULL REFERENCES users(id)
    SQL

    execute <<-SQL
      ALTER TABLE user_contacts ADD PRIMARY KEY (user_related_id,user_id);
    SQL
  end

  def self.down
    drop_table "user_contacts"
  end
end
