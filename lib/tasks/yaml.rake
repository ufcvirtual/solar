namespace :yaml do

    desc "Test YAML files"
    task :check => :environment do
      require 'yaml'
    
      d = Dir["./**/*.yml"]
      d.each do |file|
        begin
          puts "checking : #{file}"
          f = YAML.load_file(file)
        rescue Exception
          puts "failed to read #{file}: #{$!}"
        end
      end
    end
    end