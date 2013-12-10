class Notifier < ActionMailer::Base
  default YAML::load(File.open('config/mailer.yml'))['default_sender']

  def send_mail(recipients, subject, message, files, from = nil)
    files.each do |file|
      attachments[file.attachment_file_name] = File.read(file.attachment.path)
    end

    config_mail = {to: recipients, subject: "[SOLAR] #{subject}"}
    config_mail[:from] = from unless from.nil?

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

end
