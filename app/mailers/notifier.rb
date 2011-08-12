class Notifier < ActionMailer::Base
  default :from => "teste@virtual.ufc.br"
	
	def recovery_new_pwd (destiny, new_pwd)
		txt_body = t(:pwd_recovery_mail_body, :recipient => destiny.name, :login => destiny.login, :password => new_pwd )
		mail(:to => destiny.email, 
			 :subject => '[SOLAR] Recuperacao de senha', 
			 :body => txt_body) 
	end

  def send_mail (recipients, subject, message, message_path, files, from = nil)
    unless files.empty?
      files.split(";").each{ |f|
        #remove do nome de cada arquivo o caminho, o id e o "_"
        name_attachment = f.gsub(message_path,'')
        name_attachment = name_attachment.slice(name_attachment.index("_")+1..name_attachment.length)
        attachments[name_attachment] = File.read(f)
      }
    end

    if !from.nil?
      mail(:to => recipients, :from => from,
           :subject => "[SOLAR] #{subject}") do |format|
          format.text { render :text => message }
          format.html { render :text => message }
      end
    else
      mail(:to => recipients,
           :subject => "[SOLAR] #{subject}") do |format|
          format.text { render :text => message }
          format.html { render :text => message }
      end
    end
	end

end
