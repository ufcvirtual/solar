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


# constantes de status de matricula e pedido de matricula - table ALLOCATIONS
Allocation_Pending   = 0           # quando pede matricula pela 1a vez
Allocation_Activated = 1           # com matricula ativa
Allocation_Cancelled = 2           # com matricula cancelada
Allocation_Pending_Reactivate  = 3 # quando pede matricula depois de ter sido cancelado

# constante que indica numero maximo de abas abertas
Max_Tabs_Open = 4

# constantes que indicam tipos de abas que podem ser abertas
Tab_Type_Home = "0"
Tab_Type_Curriculum_Unit = "1"