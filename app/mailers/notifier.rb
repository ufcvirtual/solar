class Notifier < ActionMailer::Base
  default YAML::load(File.open('config/mailer.yml'))['default_sender']
	
	def recovery_new_pwd (destiny, new_pwd)
		txt_body = t(:pwd_recovery_mail_body, :recipient => destiny.name, :login => destiny.login, :password => new_pwd )
		mail(:to => destiny.email, 
			 :subject => '[SOLAR] Recuperacao de senha', 
			 :body => txt_body) 
	end

  def send_mail (recipients, subject, message, message_path, files, from = nil)
    unless files.empty?
      files.split(";").each{ |f|
        name_attachment = f.gsub(message_path,'') # remove do nome de cada arquivo o caminho, o id e o "_"
        name_attachment = name_attachment.slice(name_attachment.index("_")+1..name_attachment.length)
        attachments[name_attachment] = File.read(f)
      }
    end

    config_mail = {:to => recipients, :subject => "[SOLAR] #{subject}"}
    config_mail[:from] = from unless from.nil?

    mail(config_mail) do |format|
        format.text { render :text => message }
        format.html { render :text => message }
    end
	end
end
