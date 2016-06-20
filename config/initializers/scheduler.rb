require 'rubygems'
require 'rufus-scheduler'

scheduler = Rufus::Scheduler.start_new

#minutos e horas * * *
scheduler.cron '00 04 * * *' do
  Exam.correction_cron	
end