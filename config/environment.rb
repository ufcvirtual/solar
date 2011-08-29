# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Solar::Application.initialize!

# configuracoes do action mailer para o gmail - porta: 465 ou 587
ActionMailer::Base.raise_delivery_errors = false
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
		:address              => 'smtp.gmail.com',
		:port                 => 587,
		:domain               => 'www.teste.com',
		:user_name            => 'teste@teste.com',
		:password             => 'teste',
		:authentication       => 'login',
		:enable_starttls_auto => true  }


# Black list para validar envio de arquivos
Black_List = [
  # lista de arquivos fica aqui
]

# constantes de status de matricula e pedido de matricula - table ALLOCATIONS
Allocation_Pending   = 0           # quando pede matricula pela 1a vez
Allocation_Activated = 1           # com matricula ativa
Allocation_Cancelled = 2           # com matricula cancelada
Allocation_Pending_Reactivate = 3  # quando pede matricula depois de ter sido cancelado

# constantes de status de aula - table LESSONS
Lesson_Test      = 0               # aula em teste
Lesson_Approved  = 1               # aula aprovada

# constante que indica numero maximo de abas abertas
Max_Tabs_Open = 4

# constantes que indicam tipos de abas que podem ser abertas
Tab_Type_Home = "1"
Tab_Type_Curriculum_Unit = "2"

# filtros para mensagem
Message_Filter_Sender = 0b00000001   # 00000001 = eh origem            (1o bit = 1)
Message_Filter_Read   = 0b00000010   # filtro com 00000010 -> lida     (2o bit = 1)
Message_Filter_Unread = 0b11111101   # filtro com 11111101 -> nao lida (2o bit = 0)
Message_Filter_Trash  = 0b00000100   # filtro com 00000100 -> estah na lixeira (3o bit = 1)