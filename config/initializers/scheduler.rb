require 'rubygems'
require 'rufus-scheduler'

scheduler = Rufus::Scheduler.start_new

#minutos e horas * * * 03:30
scheduler.cron '30 03 * * *' do
  LogNavigation.delete_log_navigation
  LogNavigationSub.delete_log_navigation_sub
end

#minutos e horas * * * 04:00
scheduler.cron '00 04 * * *' do
  Exam.correction_cron	
end