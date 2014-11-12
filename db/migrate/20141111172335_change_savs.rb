class ChangeSavs < ActiveRecord::Migration
  def up
    drop_table :savs if table_exists? :savs

    unless SavConfig::CONFIG.nil?
      create_table :savs do |t|
        t.integer :questionnaire_id, null: false
        t.integer :allocation_tag_id, null: true
        t.integer :profile_id, null: true
        t.date :start_date, null: false
        t.date :end_date, null: false
        t.timestamp :created_at, null: false
      end
      add_foreign_key "savs", "allocation_tags", name: "savs_allocation_tag_id_fk"
      add_foreign_key "savs", "profiles", name: "savs_profile_id_fk"
      execute "ALTER TABLE savs ADD CONSTRAINT questionnaire_group_profile UNIQUE (questionnaire_id, allocation_tag_id, profile_id);"
    end
  end

  def down
    drop_table :savs if table_exists? :savs
  end
end

