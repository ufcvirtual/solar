# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20131024195306) do

  create_table "academic_allocations", :force => true do |t|
    t.integer "allocation_tag_id"
    t.integer "academic_tool_id"
    t.string  "academic_tool_type"
  end

  create_table "allocation_tags", :force => true do |t|
    t.integer "group_id"
    t.integer "offer_id"
    t.integer "curriculum_unit_id"
    t.integer "course_id"
  end

  create_table "allocations", :force => true do |t|
    t.integer "user_id",                          :null => false
    t.integer "allocation_tag_id"
    t.integer "profile_id",                       :null => false
    t.integer "status",            :default => 0
  end

  add_index "allocations", ["user_id", "allocation_tag_id", "profile_id"], :name => "allocations_unique_ids", :unique => true

  create_table "assignment_comments", :force => true do |t|
    t.integer  "sent_assignment_id", :null => false
    t.integer  "user_id",            :null => false
    t.text     "comment"
    t.datetime "updated_at"
  end

  create_table "assignment_enunciation_files", :force => true do |t|
    t.integer  "assignment_id",                         :null => false
    t.string   "attachment_file_name",                  :null => false
    t.string   "attachment_content_type", :limit => 45
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  create_table "assignment_files", :force => true do |t|
    t.integer  "sent_assignment_id",                     :null => false
    t.string   "attachment_file_name",                   :null => false
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "user_id",                 :default => 1
  end

  create_table "assignments", :force => true do |t|
    t.integer "schedule_id"
    t.string  "name",            :limit => 1024,                :null => false
    t.text    "enunciation"
    t.integer "type_assignment",                 :default => 0, :null => false
  end

  create_table "authors", :force => true do |t|
    t.integer  "bibliography_id", :null => false
    t.string   "name",            :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "bibliographies", :force => true do |t|
    t.integer  "type_bibliography",                       :null => false
    t.text     "title",                                   :null => false
    t.text     "subtitle"
    t.string   "address"
    t.string   "publisher"
    t.integer  "count_pages"
    t.string   "pages",                     :limit => 50
    t.integer  "volume"
    t.integer  "edition"
    t.integer  "publication_year"
    t.string   "periodicity"
    t.string   "issn",                      :limit => 9
    t.string   "isbn",                      :limit => 17
    t.integer  "periodicity_year_start"
    t.integer  "periodicity_year_end"
    t.text     "article_periodicity_title"
    t.integer  "fascicle"
    t.string   "publication_month",         :limit => 50
    t.text     "additional_information"
    t.text     "url"
    t.date     "accessed_in"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
  end

  create_table "chat_messages", :force => true do |t|
    t.integer  "chat_room_id",                 :null => false
    t.integer  "allocation_id",                :null => false
    t.integer  "message_type",  :default => 0, :null => false
    t.text     "text"
    t.datetime "created_at"
    t.integer  "user_id"
  end

  create_table "chat_participants", :force => true do |t|
    t.integer "chat_room_id",  :null => false
    t.integer "allocation_id", :null => false
  end

  add_index "chat_participants", ["chat_room_id", "allocation_id"], :name => "index_chat_participants_on_chat_room_id_and_allocation_id", :unique => true

  create_table "chat_rooms", :force => true do |t|
    t.integer "chat_type",   :default => 0, :null => false
    t.string  "title",                      :null => false
    t.text    "description"
    t.integer "schedule_id",                :null => false
    t.string  "start_hour"
    t.string  "end_hour"
  end

  create_table "comment_files", :force => true do |t|
    t.integer  "assignment_comment_id",   :null => false
    t.string   "attachment_file_name",    :null => false
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  create_table "contexts", :force => true do |t|
    t.string "name",      :limit => 100, :null => false
    t.string "parameter", :limit => 45
  end

  create_table "courses", :force => true do |t|
    t.string "name", :null => false
    t.string "code"
  end

  create_table "curriculum_unit_types", :force => true do |t|
    t.string  "description",       :limit => 50,                                          :null => false
    t.boolean "allows_enrollment",               :default => true
    t.string  "icon_name",         :limit => 60, :default => "icon_type_free_course.png"
  end

  create_table "curriculum_units", :force => true do |t|
    t.integer "curriculum_unit_type_id",                :null => false
    t.string  "name",                    :limit => 120, :null => false
    t.string  "code",                    :limit => 10
    t.text    "resume",                                 :null => false
    t.text    "syllabus",                               :null => false
    t.float   "passing_grade"
    t.text    "objectives",                             :null => false
    t.text    "prerequisites"
  end

  add_index "curriculum_units", ["code"], :name => "index_curriculum_unit_on_code", :unique => true

  create_table "discussion_post_files", :force => true do |t|
    t.integer  "discussion_post_id",      :null => false
    t.string   "attachment_file_name",    :null => false
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  create_table "discussion_posts", :force => true do |t|
    t.integer  "user_id",                      :null => false
    t.integer  "discussion_id",                :null => false
    t.integer  "profile_id",                   :null => false
    t.text     "content",                      :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.integer  "parent_id"
    t.integer  "level",         :default => 1
  end

  create_table "discussions", :force => true do |t|
    t.string  "name",        :limit => 120
    t.text    "description"
    t.integer "schedule_id",                :null => false
  end

  create_table "group_assignments", :force => true do |t|
    t.string   "group_name",             :null => false
    t.datetime "group_updated_at"
    t.integer  "academic_allocation_id"
  end

  create_table "group_participants", :force => true do |t|
    t.integer  "group_assignment_id",    :null => false
    t.integer  "user_id",                :null => false
    t.datetime "participant_updated_at"
  end

  create_table "groups", :force => true do |t|
    t.integer "offer_id",                   :null => false
    t.string  "code"
    t.boolean "status",   :default => true
  end

  create_table "lesson_logs", :force => true do |t|
    t.integer  "lesson_id",     :null => false
    t.integer  "allocation_id"
    t.datetime "access_date",   :null => false
  end

  create_table "lesson_modules", :force => true do |t|
    t.string  "name",        :limit => 100,                    :null => false
    t.string  "description"
    t.integer "order"
    t.boolean "is_default",                 :default => false, :null => false
  end

  create_table "lessons", :force => true do |t|
    t.integer "user_id"
    t.integer "schedule_id"
    t.string  "name",                               :null => false
    t.string  "description"
    t.string  "address",                            :null => false
    t.integer "type_lesson",                        :null => false
    t.boolean "privacy",          :default => true, :null => false
    t.integer "order",                              :null => false
    t.integer "status",           :default => 0,    :null => false
    t.integer "lesson_module_id"
  end

  create_table "logs", :force => true do |t|
    t.integer  "log_type",                           :default => 1
    t.integer  "user_id"
    t.string   "description",        :limit => 1000
    t.integer  "course_id"
    t.integer  "curriculum_unit_id"
    t.integer  "group_id"
    t.string   "session_id"
    t.datetime "created_at"
  end

  create_table "menus", :force => true do |t|
    t.integer "resource_id"
    t.string  "name",        :limit => 100
    t.string  "link"
    t.boolean "status",                     :default => true
    t.integer "order",                      :default => 999,  :null => false
    t.integer "parent_id"
  end

  create_table "menus_contexts", :id => false, :force => true do |t|
    t.integer "menu_id",    :null => false
    t.integer "context_id", :null => false
  end

  create_table "message_files", :force => true do |t|
    t.integer  "message_id"
    t.string   "message_file_name"
    t.string   "message_content_type"
    t.integer  "message_file_size"
    t.datetime "message_updated_at"
  end

  create_table "message_labels", :force => true do |t|
    t.integer "user_id"
    t.boolean "label_system",                :default => true
    t.string  "title",        :limit => 120,                   :null => false
  end

  create_table "messages", :force => true do |t|
    t.string   "subject"
    t.text     "content"
    t.datetime "send_date"
  end

  create_table "notifications", :force => true do |t|
    t.string   "title",       :null => false
    t.text     "description", :null => false
    t.integer  "schedule_id", :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "offers", :force => true do |t|
    t.integer "curriculum_unit_id"
    t.integer "course_id"
    t.integer "enrollment_schedule_id"
    t.integer "offer_schedule_id"
    t.integer "semester_id",            :null => false
  end

  create_table "permissions_menus", :id => false, :force => true do |t|
    t.integer "profile_id", :null => false
    t.integer "menu_id",    :null => false
  end

  create_table "permissions_resources", :id => false, :force => true do |t|
    t.integer "profile_id",                     :null => false
    t.integer "resource_id",                    :null => false
    t.boolean "per_id",      :default => false
    t.boolean "status",      :default => true
  end

  create_table "personal_configurations", :force => true do |t|
    t.integer "user_id",        :null => false
    t.string  "theme"
    t.string  "default_locale"
  end

  create_table "profiles", :force => true do |t|
    t.string  "name",                     :null => false
    t.integer "types",  :default => 0
    t.boolean "status", :default => true
  end

  create_table "public_files", :force => true do |t|
    t.integer  "allocation_tag_id",       :null => false
    t.integer  "user_id",                 :null => false
    t.string   "attachment_file_name",    :null => false
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  create_table "resources", :force => true do |t|
    t.string  "description",                   :null => false
    t.string  "action",                        :null => false
    t.string  "controller",                    :null => false
    t.boolean "status",      :default => true
  end

  create_table "schedule_events", :force => true do |t|
    t.string  "title",       :limit => 100
    t.text    "description"
    t.integer "schedule_id"
    t.integer "type_event",                 :default => 2, :null => false
    t.string  "start_hour"
    t.string  "end_hour"
    t.string  "place"
  end

  create_table "schedules", :force => true do |t|
    t.datetime "start_date"
    t.datetime "end_date"
  end

  create_table "semesters", :force => true do |t|
    t.string  "name",                   :null => false
    t.integer "offer_schedule_id",      :null => false
    t.integer "enrollment_schedule_id", :null => false
  end

  create_table "sent_assignments", :force => true do |t|
    t.integer "user_id"
    t.float   "grade"
    t.integer "group_assignment_id"
    t.integer "academic_allocation_id"
  end

  add_index "sent_assignments", ["academic_allocation_id", "user_id"], :name => "index_sent_assignments_on_academic_allocation_id_and_user_id", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "support_material_files", :force => true do |t|
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.string   "folder"
    t.text     "url"
    t.integer  "material_type",           :default => 0, :null => false
  end

  create_table "user_contacts", :id => false, :force => true do |t|
    t.integer "user_id",         :null => false
    t.integer "user_related_id", :null => false
  end

  create_table "user_message_labels", :id => false, :force => true do |t|
    t.integer "user_message_id",  :null => false
    t.integer "message_label_id", :null => false
  end

  create_table "user_messages", :force => true do |t|
    t.integer "message_id"
    t.integer "user_id"
    t.integer "status"
  end

  create_table "users", :force => true do |t|
    t.string   "name",                   :limit => 100
    t.string   "nick",                   :limit => 35,                    :null => false
    t.string   "username",                                                :null => false
    t.date     "birthdate"
    t.string   "enrollment_code",        :limit => 20
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "special_needs",          :limit => 50
    t.string   "address",                :limit => 100
    t.integer  "address_number"
    t.string   "address_complement",     :limit => 50
    t.string   "address_neighborhood",   :limit => 50
    t.string   "zipcode",                :limit => 11
    t.string   "country",                :limit => 100
    t.string   "state",                  :limit => 100
    t.string   "city",                   :limit => 100
    t.string   "telephone",              :limit => 20
    t.string   "cell_phone",             :limit => 20
    t.string   "institution",            :limit => 120
    t.boolean  "gender"
    t.string   "cpf",                    :limit => 14
    t.string   "alternate_email"
    t.text     "bio"
    t.text     "interests"
    t.text     "music"
    t.text     "movies"
    t.text     "books"
    t.text     "phrase"
    t.text     "site"
    t.string   "email",                                 :default => "",   :null => false
    t.string   "encrypted_password",                    :default => "",   :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string   "password_salt"
    t.string   "authentication_token"
    t.boolean  "active",                                :default => true, :null => false
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  add_foreign_key "academic_allocations", "allocation_tags", :name => "academic_allocations_allocation_tag_id_fk"

  add_foreign_key "allocation_tags", "courses", :name => "allocation_tags_course_id_fk"
  add_foreign_key "allocation_tags", "curriculum_units", :name => "allocation_tags_curriculum_unit_id_fk"
  add_foreign_key "allocation_tags", "groups", :name => "allocation_tags_group_id_fk"
  add_foreign_key "allocation_tags", "offers", :name => "allocation_tags_offer_id_fk"

  add_foreign_key "allocations", "allocation_tags", :name => "allocations_allocation_tag_id_fk"
  add_foreign_key "allocations", "profiles", :name => "allocations_profile_id_fk"
  add_foreign_key "allocations", "users", :name => "allocations_user_id_fk"

  add_foreign_key "assignment_comments", "sent_assignments", :name => "assignment_comments_sent_assignment_id_fk"
  add_foreign_key "assignment_comments", "users", :name => "assignment_comments_user_id_fk"

  add_foreign_key "assignment_enunciation_files", "assignments", :name => "assignment_enunciation_files_assignment_id_fk"

  add_foreign_key "assignment_files", "sent_assignments", :name => "assignment_files_sent_assignment_id_fk"

  add_foreign_key "assignments", "schedules", :name => "assignments_schedule_id_fk"

  add_foreign_key "authors", "bibliographies", :name => "authors_bibliography_id_fk"

  add_foreign_key "chat_messages", "allocations", :name => "chat_messages_allocation_id_fk"
  add_foreign_key "chat_messages", "chat_rooms", :name => "chat_messages_chat_room_id_fk"
  add_foreign_key "chat_messages", "users", :name => "chat_messages_user_id_fk"

  add_foreign_key "chat_participants", "allocations", :name => "chat_participants_allocation_id_fk"
  add_foreign_key "chat_participants", "chat_rooms", :name => "chat_participants_chat_room_id_fk"

  add_foreign_key "chat_rooms", "schedules", :name => "chat_rooms_schedule_id_fk"

  add_foreign_key "comment_files", "assignment_comments", :name => "comment_files_assignment_comment_id_fk"

  add_foreign_key "curriculum_units", "curriculum_unit_types", :name => "curriculum_units_curriculum_unit_type_id_fk"

  add_foreign_key "discussion_post_files", "discussion_posts", :name => "discussion_post_files_discussion_post_id_fk"

  add_foreign_key "discussion_posts", "discussion_posts", :name => "discussion_posts_parent_id_fkey", :column => "parent_id"
  add_foreign_key "discussion_posts", "discussions", :name => "discussion_posts_discussion_id_fk"
  add_foreign_key "discussion_posts", "profiles", :name => "discussion_posts_profile_id_fk"
  add_foreign_key "discussion_posts", "users", :name => "discussion_posts_user_id_fk"

  add_foreign_key "discussions", "schedules", :name => "discussions_schedule_id_fk"

  add_foreign_key "group_assignments", "academic_allocations", :name => "group_assignments_academic_allocation_id_fk"

  add_foreign_key "group_participants", "group_assignments", :name => "group_participants_group_assignment_id_fk"
  add_foreign_key "group_participants", "users", :name => "group_participants_user_id_fk"

  add_foreign_key "groups", "offers", :name => "groups_offer_id_fk"

  add_foreign_key "lesson_logs", "allocations", :name => "lesson_logs_allocation_id_fk"
  add_foreign_key "lesson_logs", "lessons", :name => "lesson_logs_lesson_id_fk"

  add_foreign_key "lessons", "lesson_modules", :name => "lessons_lesson_module_id_fk"
  add_foreign_key "lessons", "schedules", :name => "lessons_schedule_id_fk"
  add_foreign_key "lessons", "users", :name => "lessons_user_id_fk"

  add_foreign_key "menus", "menus", :name => "menus_parent_id_fkey", :column => "parent_id"
  add_foreign_key "menus", "resources", :name => "menus_resource_id_fk"

  add_foreign_key "menus_contexts", "contexts", :name => "menus_contexts_context_id_fk"
  add_foreign_key "menus_contexts", "menus", :name => "menus_contexts_menu_id_fk"

  add_foreign_key "message_files", "messages", :name => "message_files_message_id_fk"

  add_foreign_key "message_labels", "users", :name => "message_labels_user_id_fk"

  add_foreign_key "notifications", "schedules", :name => "notifications_schedule_id_fk"

  add_foreign_key "offers", "courses", :name => "offers_course_id_fk"
  add_foreign_key "offers", "curriculum_units", :name => "offers_curriculum_unit_id_fk"
  add_foreign_key "offers", "schedules", :name => "offers_enrollment_schedule_id_fk", :column => "enrollment_schedule_id"
  add_foreign_key "offers", "schedules", :name => "offers_offer_schedule_id_fk", :column => "offer_schedule_id"
  add_foreign_key "offers", "semesters", :name => "offers_semester_id_fk"

  add_foreign_key "permissions_menus", "menus", :name => "permissions_menus_menu_id_fk"
  add_foreign_key "permissions_menus", "profiles", :name => "permissions_menus_profile_id_fk"

  add_foreign_key "permissions_resources", "profiles", :name => "permissions_resources_profile_id_fk"
  add_foreign_key "permissions_resources", "resources", :name => "permissions_resources_resource_id_fk"

  add_foreign_key "personal_configurations", "users", :name => "personal_configurations_user_id_fk"

  add_foreign_key "public_files", "allocation_tags", :name => "public_files_allocation_tag_id_fk"
  add_foreign_key "public_files", "users", :name => "public_files_user_id_fk"

  add_foreign_key "schedule_events", "schedules", :name => "schedule_events_schedule_id_fk"

  add_foreign_key "semesters", "schedules", :name => "semesters_enrollment_schedule_id_fk", :column => "enrollment_schedule_id"
  add_foreign_key "semesters", "schedules", :name => "semesters_offer_schedule_id_fk", :column => "offer_schedule_id"

  add_foreign_key "sent_assignments", "academic_allocations", :name => "sent_assignments_academic_allocation_id_fk"
  add_foreign_key "sent_assignments", "users", :name => "sent_assignments_user_id_fk"

  add_foreign_key "user_contacts", "users", :name => "user_contacts_user_id_fkey"
  add_foreign_key "user_contacts", "users", :name => "user_contacts_user_related_id_fkey", :column => "user_related_id"

  add_foreign_key "user_message_labels", "message_labels", :name => "user_message_labels_message_label_id_fk"
  add_foreign_key "user_message_labels", "user_messages", :name => "user_message_labels_user_message_id_fk"

  add_foreign_key "user_messages", "messages", :name => "user_messages_message_id_fk"
  add_foreign_key "user_messages", "users", :name => "user_messages_user_id_fk"

end
