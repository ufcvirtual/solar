class AddSemesterToSav < ActiveRecord::Migration
  def up
    unless SavConfig::CONFIG.nil?
        add_column :savs, :semester_id, :integer, null: true
        add_column :savs, :percent, :float, null: true
        change_column :savs, :start_date, :date, null: true
        change_column :savs, :end_date, :date, null: true
        add_foreign_key "savs", "semesters", name: "savs_semester_id_fk"
        execute "ALTER TABLE savs DROP CONSTRAINT questionnaire_group_profile;"
        execute "ALTER TABLE savs ADD CONSTRAINT questionnaire_group_profile UNIQUE (questionnaire_id, allocation_tag_id, semester_id, profile_id);"
    end
  end

  def down
    unless SavConfig::CONFIG.nil?
        remove_column :savs, :semester_id
        remove_column :savs, :percent
        execute "ALTER TABLE savs ADD CONSTRAINT questionnaire_group_profile UNIQUE (questionnaire_id, allocation_tag_id, profile_id);"
    end
  end
end
