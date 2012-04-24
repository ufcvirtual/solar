require 'active_record/fixtures.rb'

puts "::Production Seed::"

Fixtures.reset_cache
fixtures_folder = File.join(::Rails.root.to_s, 'spec', 'fixtures', 'production')
fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml')}

puts "  - Executando fixtures: #{fixtures}"
Fixtures.create_fixtures(fixtures_folder, fixtures)
