class CreateSavs < ActiveRecord::Migration
  def up
    unless SavConfig::CONFIG.nil?
      create_table :savs do |t|
        t.integer :sav_id, null: false
        t.integer :group_id, null: true
        t.date :start_date, null: false
        t.date :end_date, null: false
        t.timestamp :created_at, null: false
      end
      add_foreign_key "savs", "groups", name: "savs_group_id_fk"
      # execute "ALTER TABLE savs ADD PRIMARY KEY (sav_id,group_id);"
      execute "CREATE UNIQUE INDEX sav_group ON savs (sav_id, group_id);"
    end
  end
  def down
    drop_table :savs if table_exists? :savs
  end
end
