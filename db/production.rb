require 'active_record/fixtures.rb'

puts "Production Seed"

puts "Truncando tabelas"

# TEMPORARIO - MODIFICAR ESTA PARTE -> 2011/07/06
ActiveRecord::Base.connection.select_all "TRUNCATE discussions CASCADE;"
ActiveRecord::Base.connection.select_all "TRUNCATE discussion_posts CASCADE;"
ActiveRecord::Base.connection.select_all "TRUNCATE lessons CASCADE;"
ActiveRecord::Base.connection.select_all "TRUNCATE assignments CASCADE;"
ActiveRecord::Base.connection.select_all "TRUNCATE calendar_events CASCADE;"


models = [Allocation, Bibliography, UserMessageLabel, UserMessage, MessageLabel,
  AssignmentComment, SendAssignment, Assignment, Agenda, AllocationTag, PermissionsResource, PermissionsMenu, Menu, Resource, Profile, Group,
  Enrollment, Offer, CurriculumUnit, CurriculumUnitType, Course, PersonalConfiguration, User]
models.each(&:delete_all)

Fixtures.reset_cache
fixtures_folder = File.join(::Rails.root.to_s, 'spec', 'fixtures')
fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }

puts "  - Executando fixtures: #{fixtures}"

Fixtures.create_fixtures(fixtures_folder, fixtures)

puts "Setando permissoes"

# executa o arquivo de permissoes
require File.join(::Rails.root.to_s, 'db', 'permissions')