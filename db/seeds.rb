puts "- Environment: #{Rails.env} - Executando fixtures"
Rake::Task['db:fixtures:load'].invoke
