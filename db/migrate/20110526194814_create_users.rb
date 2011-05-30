class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users" do |t|
      t.string   "login", :null => false
      t.string   "email", :null => false
      t.string   "crypted_password", :null => false
      t.string   "password_salt"
      t.string   "persistence_token"
      t.integer  "login_count", :default => 0, :null => false
      t.integer  "failed_login_count", :default => 0, :null => false
      t.datetime "last_request_at"
      t.datetime "current_login_at"
      t.datetime "last_login_at"
      t.string   "current_login_ip"
      t.string   "last_login_ip"
      t.string   "name",                 :limit => 100
      t.string   "nick",                 :limit => 35, :null => false
      t.date     "birthdate"
      t.string   "enrollment_code",      :limit => 20
      t.string   "status",               :limit => 1
      t.string   "photo_file_name"
      t.string   "photo_content_type"
      t.integer  "photo_file_size"
      t.datetime "photo_updated_at"
      t.string   "special_needs",        :limit => 50
      t.string   "address",              :limit => 100
      t.integer  "address_number"
      t.string   "address_complement",   :limit => 50
      t.string   "address_neighborhood", :limit => 50
      t.string   "zipcode",              :limit => 11
      t.string   "country",              :limit => 100
      t.string   "state",                :limit => 100
      t.string   "city",                 :limit => 100
      t.string   "telephone",            :limit => 20
      t.string   "cell_phone",           :limit => 20
      t.string   "institution",          :limit => 120
      t.boolean  "gender"
      t.string   "cpf",                  :limit => 14
      t.string   "alternate_email"
      t.text     "bio"
      t.text     "interests"
      t.text     "music"
      t.text     "movies"
      t.text     "books"
      t.text     "phrase"
      t.text     "site"
    end

    add_index "users", ["email"], :name => "index_users_on_email", :unique => true
    add_index "users", ["login"], :name => "index_users_on_login", :unique => true
    add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token", :unique => true

  end

  def self.down
    drop_table "users"
  end
end
