class Notifier < ActionMailer::Base
  default :from => "teste@virtual.ufc.br"
	
	def recovery_new_pwd (destiny, new_pwd)
		txt_body = "Caro(a) #{destiny.name}, \n\nSua nova senha para acessar o Solar eh:\n     #{new_pwd}"
		txt_body += "\n\nAtenciosamente,\nAdministracao do ambiente"
		txt_body += "\n\nAmbiente Virtual SOLAR: http://www.solar2.virtual.ufc.br"
		txt_body += "\n\n\n[Esta eh uma mensagem automatica. Por favor, nao a responda.]"
		mail(:to => destiny.email, 
			 :subject => '[SOLAR] Recuperacao de senha', 
			 :body => txt_body) 
	end

end
