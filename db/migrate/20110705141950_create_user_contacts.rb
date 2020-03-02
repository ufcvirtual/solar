class CreateUserContacts < ActiveRecord::Migration[5.0]
  def self.up
    create_table(:user_contacts, id: false) do |t|
      t.column :user_id, :integer
      t.column :user_related_id, :integer
    end
    add_foreign_key :user_contacts, :users
    add_foreign_key :user_contacts, :users, column: :user_related_id


    execute <<-SQL
      ALTER TABLE user_contacts ADD PRIMARY KEY (user_related_id,user_id);
    SQL
  end

  def self.down
    drop_table "user_contacts"
  end
end
