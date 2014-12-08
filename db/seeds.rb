puts "\n- Environment: #{Rails.env}"
puts " |-- Executando fixtures\n"

Rake::Task['db:fixtures:load'].invoke if Rails.env.in?(['development', 'test'])

## Setup Production
if Rails.env == 'production'
  ENV["FIXTURES"] = "contexts,profiles,resources,permissions_resources,menus,menus_contexts,curriculum_unit_types"
  Rake::Task["db:fixtures:load"].invoke

  admin = User.new email: 'admin@admin.com', name: 'Administrator', nick: 'Admin', username: 'admin', password: '123456', cpf: '48248246566', birthdate: Date.today
  admin.save

  admin.allocations.build(profile_id: 6, status: 1).save
end

ActiveRecord::Base.connection.execute <<-SQL
  TRUNCATE related_taggables;

  INSERT INTO related_taggables (group_id, group_at_id, group_status, offer_id, offer_at_id, semester_id,
              curriculum_unit_id, curriculum_unit_at_id, course_id, course_at_id, curriculum_unit_type_id, curriculum_unit_type_at_id, offer_schedule_id)
    SELECT * FROM vw_at_related_groups;

  INSERT INTO related_taggables (offer_id, offer_at_id, semester_id, curriculum_unit_id, curriculum_unit_at_id,
              course_id, course_at_id, curriculum_unit_type_id, curriculum_unit_type_at_id, offer_schedule_id)
    SELECT * FROM vw_at_related_offers;

  INSERT INTO related_taggables (course_id, course_at_id)
      SELECT course_id, id AS course_at_id
        FROM allocation_tags WHERE course_id IS NOT NULL;

  INSERT INTO related_taggables (curriculum_unit_id, curriculum_unit_at_id, curriculum_unit_type_id, curriculum_unit_type_at_id)
    SELECT * FROM vw_at_related_curriculum_units;

  INSERT INTO related_taggables (curriculum_unit_type_id, curriculum_unit_type_at_id)
      SELECT curriculum_unit_type_id, id AS curriculum_unit_type_at_id
        FROM allocation_tags WHERE curriculum_unit_type_id IS NOT NULL;
SQL

puts " |-- Fixtures ok\n\n"
