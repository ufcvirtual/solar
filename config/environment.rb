# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Solar::Application.initialize!

# configuracoes do action mailer para o gmail - porta: 465 ou 587
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
		:address              => 'smtp.gmail.com',
		:port                 => 587,  
		:domain               => 'domain',
		:user_name            => 'teste@domain.br',		
		:password             => '123456',
		:authentication       => 'login',
		:enable_starttls_auto => true  }

# constantes de tipo de unidade curricular
Presential_Undergraduate_Course = 1
Distance_Undergraduate_Course = 2
Free_Course = 3
Extension_Course = 4
Presential_Graduate_Course = 5
Distance_Graduate_Course = 6

# constantes de tipo de perfil
Student = 1

# constantes de status de matricula e pedido de matricula
Allocation_Pending   = 0           # quando pede matricula pela 1a vez
Allocation_Activated = 1           # com matricula ativa
Allocation_Cancelled = 2           # com matricula cancelada
Allocation_Pending_Reactivate  = 3 # quando pede matricula depois de ter sido cancelado
