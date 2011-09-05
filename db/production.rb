require 'active_record/fixtures.rb'

puts "Production Seed"

puts "Truncando tabelas"

models = [DiscussionPostFile, DiscussionPost, Discussion, Lesson, Allocation, Bibliography, UserMessageLabel, UserMessage, MessageLabel,
  PublicFile, CommentFile, AssignmentFile, CommentFile, AssignmentComment, SendAssignment, Assignment,
  ScheduleEvent, Schedule, AllocationTag,
  PermissionsResource, PermissionsMenu, Menu, Resource, Profile, Group,
  Enrollment, Offer, CurriculumUnit, CurriculumUnitType, Course, PersonalConfiguration, User, Log]
models.each(&:delete_all)

Fixtures.reset_cache
fixtures_folder = File.join(::Rails.root.to_s, 'spec', 'fixtures')
fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml')}

puts "  - Executando fixtures: #{fixtures}"

Fixtures.create_fixtures(fixtures_folder, fixtures)

puts "Setando permissoes"

# executa o arquivo de permissoes
require File.join(::Rails.root.to_s, 'db', 'permissions')