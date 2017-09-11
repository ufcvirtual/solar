module BulkEmailHelper
  def send_mass_email(emails, message)
    jobs = Delayed::Job.where(failed_at: nil)

    emails_in_jobs = []
    jobs.each do |job|
      emails_in_jobs += job.handler.scan(/[A-Za-z0-9._-]+@\w+/)
    end

    max_size = 500
    quantum_time = 480

    self_email = message.sender.email.scan(/[A-Za-z0-9._-]+@\w+/).first
    emails_in_jobs.delete(self_email)
    offset = emails_in_jobs.uniq.size
    excess = offset % max_size

    if emails.size > max_size * 0.7
      time = excess > max_size * 0.3 ? offset + quantum_time : offset
    else
      time = excess > max_size * 0.7 ? offset + quantum_time : offset
    end

    count = 0
    while count < emails.size
      Notifier.delay(run_at: (time/16).minutes.from_now).send_mail(emails.slice(count, max_size), message.subject, new_msg_template, message.files, message.sender.email)
      time += quantum_time
      count += max_size
    end
  end
end
