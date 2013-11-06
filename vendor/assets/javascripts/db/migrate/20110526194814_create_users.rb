class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users" do |t|
      t.string   "name", :limit => 100
      t.string   "nick", :limit => 35, :null => false
      t.string   "username", :null => false, :unique => true
      t.date     "birthdate"
      t.string   "enrollment_code",      :limit => 20
      t.string   "photo_file_name"
      t.string   "photo_content_type"
      t.integer  "photo_file_size"
      t.datetime "photo_updated_at"
      t.string   "special_needs", :limit => 50
      t.string   "address", :limit => 100
      t.integer  "address_number"
      t.string   "address_complement", :limit => 50
      t.string   "address_neighborhood", :limit => 50
      t.string   "zipcode", :limit => 11
      t.string   "country", :limit => 100
      t.string   "state", :limit => 100
      t.string   "city", :limit => 100
      t.string   "telephone", :limit => 20
      t.string   "cell_phone", :limit => 20
      t.string   "institution", :limit => 120
      t.boolean  "gender"
      t.string   "cpf", :limit => 14
      t.string   "alternate_email"
      t.text     "bio"
      t.text     "interests"
      t.text     "music"
      t.text     "movies"
      t.text     "books"
      t.text     "phrase"
      t.text     "site"
      t.string   "status", :limit => 1
    end
  end

  def self.down
    drop_table "users"
  end
end
