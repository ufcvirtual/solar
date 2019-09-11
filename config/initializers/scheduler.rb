require 'rubygems'
require 'rufus-scheduler'

if (YAML::load(File.open('config/global.yml'))[Rails.env.to_s]['run_scheduler'] rescue false)

  scheduler = Rufus::Scheduler.new

  #minutos e horas * * * 03:30
  scheduler.cron '30 03 * * *' do
    LogNavigation.delete_log_navigation
    LogNavigationSub.delete_log_navigation_sub
  end

  #minutos e horas * * * 04:00
  scheduler.cron '00 04 * * *' do
    Exam.correction_cron
  end

  #execute, a cada 60 segundos, após o inicio do sistema
  scheduler.in '60s' do
    Job.job_send_mail
  end
  #execute a cada 15 minutos
  if (YAML::load(File.open('config/mailer.yml'))['mass_emails']['scheduled_time'] rescue false)
    scheduler.every "#{YAML::load(File.open('config/mailer.yml'))['mass_emails']['scheduled_time']}m" do
      Job.job_send_mail
    end
  end

end

