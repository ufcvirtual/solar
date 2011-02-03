class Notifier < ActionMailer::Base
  default :from => "teste@virtual.ufc.br"
	
	def msg (text)
		mail(:to => 'patricia@virtual.ufc.br', 
			 :bc => 'humberto@virtual.ufc.br',
			 :subject => 'recuperacao de senha do novo solar', 
			 :body => 'sua nova senha eh '+text) 
	end

end
