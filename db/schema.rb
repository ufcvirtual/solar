# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110218193045) do

  create_table "allocations", :force => true do |t|
    t.integer  "users_id"
    t.integer  "groups_id"
    t.integer  "profiles_id"
    t.boolean  "status",      :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "courses", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "curriculum_unities", :force => true do |t|
    t.string   "name",          :null => false
    t.string   "code",          :null => false
    t.text     "description"
    t.text     "syllabus"
    t.float    "passing_grade"
    t.integer  "category",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "curriculum_unities", ["category"], :name => "index_curriculum_unit_on_category"
  add_index "curriculum_unities", ["code"], :name => "index_curriculum_unit_on_code", :unique => true

  create_table "enrollments", :force => true do |t|
    t.integer  "offers_id"
    t.date     "start",      :null => false
    t.date     "end",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", :force => true do |t|
    t.integer  "offers_id"
    t.string   "code"
    t.boolean  "status",     :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "logs", :force => true do |t|
    t.integer  "log_type"
    t.string   "message"
    t.integer  "userId"
    t.integer  "profileId"
    t.integer  "courseId"
    t.integer  "classId"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "offers", :force => true do |t|
    t.integer  "curriculum_unities_id"
    t.integer  "courses_id"
    t.string   "semester"
    t.date     "start",                 :null => false
    t.date     "end",                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "personal_configurations", :force => true do |t|
    t.string   "theme"
    t.string   "mysolar_portlets"
    t.string   "default_locale"
    t.integer  "user_id",          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "personal_configurations", ["user_id"], :name => "index_user_on_personal_configuration", :unique => true

  create_table "profiles", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                                              :null => false
    t.string   "email",                                              :null => false
    t.string   "crypted_password",                                   :null => false
    t.string   "password_salt"
    t.string   "persistence_token"
    t.integer  "login_count",                         :default => 0, :null => false
    t.integer  "failed_login_count",                  :default => 0, :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                 :limit => 100
    t.string   "nick",                 :limit => 35
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
    t.boolean  "sex"
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

  add_foreign_key "allocations", ["users_id"], "users", ["id"], :name => "allocations_users_id_fkey"
  add_foreign_key "allocations", ["groups_id"], "groups", ["id"], :name => "allocations_groups_id_fkey"
  add_foreign_key "allocations", ["profiles_id"], "profiles", ["id"], :name => "allocations_profiles_id_fkey"

  add_foreign_key "enrollments", ["offers_id"], "offers", ["id"], :name => "enrollments_offers_id_fkey"

  add_foreign_key "groups", ["offers_id"], "offers", ["id"], :name => "groups_offers_id_fkey"

  add_foreign_key "offers", ["curriculum_unities_id"], "curriculum_unities", ["id"], :name => "offers_curriculum_unities_id_fkey"
  add_foreign_key "offers", ["courses_id"], "courses", ["id"], :name => "offers_courses_id_fkey"

  add_foreign_key "personal_configurations", ["user_id"], "users", ["id"], :name => "personal_configurations_user_id_fkey"

end
