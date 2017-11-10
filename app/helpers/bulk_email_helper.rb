module BulkEmailHelper

  def send_mass_email(emails, message)
    #blocos de emails
    max_size = 500
    emails_in_jobs = emails.in_groups_of(max_size, false).to_a

    emails_in_jobs.each do |e|
        job = Notifier.delay.send_mail(e, message.subject, new_msg_template, message.files, message.sender.email)
        job.amount = e.count
        job.save!
    end
    Notifier.job_send_mail 
  end
  
end