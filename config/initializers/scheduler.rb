require 'rubygems'
require 'rufus-scheduler'

if (ENV["SCHEDULER"] == "true")

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
  unless (ENV["MASS_EMAILS_SCHEDULED_TIME"].blank?)
    scheduler.every "#{ENV["MASS_EMAILS_SCHEDULED_TIME"].to_i}m" do
      Job.job_send_mail
    end
  end

  #minutos e horas * * * 14:06
  #scheduler.cron '06 14 * * *' do
  #  GroupAssignment.split_students_in_groups #criação automática de grupos de trabalho
  #end

  #minutos e horas * * * 15:05
  scheduler.cron '05 15 * * *' do
    GroupAssignment.send_email_one_week_before_start_assignment_in_group
  end

end

