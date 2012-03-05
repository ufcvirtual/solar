require 'active_record/fixtures.rb'

puts "::Development Seed::"

puts " - Truncando tabelas"

models = [SupportMaterialFile,DiscussionPostFile, DiscussionPost, Discussion, Lesson, Allocation, Bibliography, UserMessageLabel, UserMessage, MessageLabel,
  PublicFile, CommentFile, AssignmentFile, CommentFile, AssignmentComment, SendAssignment, Assignment,
  ScheduleEvent, Schedule, AllocationTag,
  PermissionsResource, PermissionsMenu, MenusContexts, Menu, Resource, Profile, Group,
  Enrollment, Offer, CurriculumUnit, CurriculumUnitType, Course, PersonalConfiguration, User, Log]
models.each(&:delete_all)

Fixtures.reset_cache
fixtures_folder = File.join(::Rails.root.to_s, 'spec', 'fixtures')
fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml')}

puts "  - Executando fixtures: #{fixtures}"

Fixtures.create_fixtures(fixtures_folder, fixtures)

# Criando resources
require File.join(::Rails.root.to_s, 'db', 'production', 'resources')
require File.join(::Rails.root.to_s, 'db', 'production', 'permissions')

allocations = Allocation.create([
    {:user_id => 1, :profile_id => 12, :status => 1},
    {:user_id => 1, :allocation_tag_id => 1, :profile_id => 1, :status => 1},
    {:user_id => 1, :allocation_tag_id => 2, :profile_id => 1, :status => 1},
    {:user_id => 1, :allocation_tag_id => 3, :profile_id => 1, :status => 1},
    {:user_id => 1, :allocation_tag_id => 8, :profile_id => 1, :status => 0},
    {:user_id => 1, :allocation_tag_id => 9, :profile_id => 1, :status => 1},

    {:user_id => 6, :allocation_tag_id => 4, :profile_id => 2, :status => 1},
    {:user_id => 6, :allocation_tag_id => 5, :profile_id => 2, :status => 1},
    {:user_id => 6, :allocation_tag_id => 6, :profile_id => 2, :status => 1},
    {:user_id => 6, :profile_id => 12, :status => 1},

    {:user_id => 7, :allocation_tag_id => 1, :profile_id => 1, :status => 1},
    {:user_id => 7, :allocation_tag_id => 2, :profile_id => 1, :status => 1},
    {:user_id => 7, :allocation_tag_id => 3, :profile_id => 1, :status => 1},
    {:user_id => 7, :profile_id => 12, :status => 1},

    {:user_id => 8, :allocation_tag_id => 1, :profile_id => 1, :status => 1},
    {:user_id => 8, :allocation_tag_id => 2, :profile_id => 1, :status => 1},
    {:user_id => 8, :allocation_tag_id => 3, :profile_id => 1, :status => 1},
    {:user_id => 8, :profile_id => 12, :status => 1},

    {:user_id => 9, :allocation_tag_id => 1, :profile_id => 1, :status => 1},
    {:user_id => 9, :allocation_tag_id => 2, :profile_id => 1, :status => 1},
    {:user_id => 9, :allocation_tag_id => 3, :profile_id => 1, :status => 1},
    {:user_id => 9, :profile_id => 12, :status => 1},

    {:user_id => 11, :allocation_tag_id => 2, :profile_id => 3, :status => 1},
    {:user_id => 11, :allocation_tag_id => 3, :profile_id => 3, :status => 1},
    {:user_id => 11, :profile_id => 12, :status => 1},

    {:user_id => 10, :allocation_tag_id => 2, :profile_id => 4, :status => 1},
    {:user_id => 10, :allocation_tag_id => 3, :profile_id => 4, :status => 1},
    {:user_id => 10, :profile_id => 12, :status => 1},

    {:user_id => 12, :allocation_tag_id => 8, :profile_id => 5, :status => 1},
    {:user_id => 12, :profile_id => 12, :status => 1}
  ])