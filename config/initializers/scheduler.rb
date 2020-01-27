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

  #minutos e horas * * * 00:01
  scheduler.cron '06 14 * * *' do
    GroupAssignment.split_students_in_groups #criação automática de grupos de trabalho
  end

  #minutos e horas * * * 00:10
  scheduler.cron '10 0 * * *' do
    Group.management_groups
  end

end

