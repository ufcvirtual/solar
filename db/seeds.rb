puts "\n- Environment: #{Rails.env}"
puts " |-- Executando fixtures\n"

Rake::Task['db:fixtures:load'].invoke if Rails.env.in?(['development', 'test'])

## Setup Production
if Rails.env == 'production'
  ENV["FIXTURES"] = "contexts,profiles,resources,permissions_resources,menus,menus_contexts,curriculum_unit_types"
  Rake::Task["db:fixtures:load"].invoke

  admin = User.new email: 'admin@admin.com', name: 'Administrator', nick: 'Admin', username: 'admin', password: '123456', cpf: '48248246566', birthdate: Date.today
  admin.save
end

puts " |-- Fixtures ok\n\n"
