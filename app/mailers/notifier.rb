class Notifier < ActionMailer::Base
  default :from => "teste@virtual.ufc.br"
	
	def recovery_new_pwd (destiny, new_pwd)
		txt_body = t(:pwd_recovery_mail_body, :recipient => destiny.name, :login => destiny.login, :password => new_pwd )
		mail(:to => destiny.email, 
			 :subject => '[SOLAR] Recuperacao de senha', 
			 :body => txt_body) 
	end

  def send_mail (recipients, subject, message, from = nil)
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
