namespace :deploy do
  desc "Seta .env.production"
  task :env_setup do
    on roles(:all) do |host|
      env_file = case ENV['SOLAR_APP']
                 when 'solar_cursos'
                   host.roles.include?(:jobs) ? '.env.cursos_jobs' : '.env.cursos'
                 else
                   host.roles.include?(:jobs) ? '.env.solar_jobs' : '.env.solar'
                 end

      execute "ln -nfs #{shared_path}/config/envs/#{env_file} #{release_path}/.env"
    end
  end
  before 'deploy:symlink:shared', 'deploy:env_setup'
end