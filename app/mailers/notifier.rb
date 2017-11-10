
class Notifier < ActionMailer::Base
  include BulkEmailHelper
  
  default YAML::load(File.open('config/mailer.yml'))['default_sender']

  def send_mail(recipients, subject, message, files, from = nil)
  
    files.each do |file|
      attachments[file.attachment_file_name] = File.read(file.attachment.path)
    end

    config_mail = { to: recipients, subject: "[SOLAR] #{subject}" }
    config_mail[:reply_to] = from unless from.nil?

    mail(config_mail) do |format|
      format.text { render text: message }
      format.html { render text: message }
    end
  end

  def enrollment_accepted(recipient, group)
    @group = group
    mail(to: recipient,
         subject: t(:subject, scope: [:notifier, :enrollment_accepted]))
  end

  def new_user(user, password)
    @user, @password = user, password
    mail(to: @user.email,
         subject: "[SOLAR] Novo Cadastro")
  end

  def change_user(user, token=nil, password=nil)
    @user, @token, @password = user, token, password
    mail(to: @user.email,
         subject: "[SOLAR] Mudança de dados de acesso")
  end

  def groups_disabled(emails, groups_codes, offer_info)
    @groups_codes, @offer_info = groups_codes, offer_info
    mail(to: emails,
         subject: t("notifier.groups_disabled.subject"))
  end

  def imported_from_private(lesson)
    @lesson = lessson
    mail(to: @lesson.user.email,
         subject: t('notifier.imported_from_private.subject'))
  end

  def job_send_mail
    amount = Job.count_jobs_30_minute
    jobs = Job.list_jobs_not_send
    jobs.each do |job|
      amount = amount + job.amount
      if amount <= 500
        clone_job = job.dup
        Delayed::Worker.new.run(job) 
        Job.update_status_job(clone_job)
      end  
    end
    Job.delete_jobs
  end 

end
