# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Solar::Application.initialize!

# configuracoes do action mailer para o 132 - funcionou
#ActionMailer::Base.delivery_method = :smtp
#ActionMailer::Base.smtp_settings = {
#		:address              => '200.129.43.132',
#		:port                 => 25 }

# configuracoes do action mailer para o gmail - porta: 465 ou 587
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
		:address              => 'smtp.gmail.com',
		:port                 => 587,  
		:domain               => 'www.virtual.ufc.br',
		:user_name            => 'informacao@virtual.ufc.br',		
		:password             => '!info@',
		:authentication       => 'login',
		:enable_starttls_auto => true  }
