class Notifier < ActionMailer::Base
  default :from => "teste@virtual.ufc.br"
	
	def recovery_new_pwd (destiny, new_pwd)
		txt_body = t(:pwd_recovery_mail_body, :recipient => destiny.name, :password => new_pwd )
		mail(:to => destiny.email, 
			 :subject => '[SOLAR] Recuperacao de senha', 
			 :body => txt_body) 
	end

end
