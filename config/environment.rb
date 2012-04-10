# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Solar::Application.initialize!

mailer_config = YAML::load(File.open('config/mailer.yml'))

# configuracoes do action mailer para o gmail - porta: 465 ou 587
ActionMailer::Base.perform_deliveries 	= true
ActionMailer::Base.delivery_method 		= :smtp
ActionMailer::Base.default_url_options 	= mailer_config['default_url_options']
ActionMailer::Base.smtp_settings 		= mailer_config['smtp_settings']

# constantes de status de matricula e pedido de matricula - table ALLOCATIONS
Allocation_Pending   = 0           # quando pede alocação(matricula) pela 1a vez
Allocation_Activated = 1           # com alocação ativa
Allocation_Cancelled = 2           # com alocação cancelada
Allocation_Pending_Reactivate = 3  # quando pede alocação(matricula) depois de ter sido cancelado

# constantes de status de aula - table LESSONS
Lesson_Test      = 0               # aula em teste
Lesson_Approved  = 1               # aula aprovada

# constante que indica numero maximo de abas abertas
Max_Tabs_Open = 4

# filtros para mensagem
Message_Filter_Sender  = 0b00000001   # 00000001 = eh origem            (1o bit = 1)
Message_Filter_Read    = 0b00000010   # filtro com 00000010 -> lida     (2o bit = 1)
Message_Filter_Unread  = 0b11111101   # filtro com 11111101 -> nao lida (2o bit = 0)
Message_Filter_Trash   = 0b00000100   # filtro com 00000100 -> estah na lixeira   (3o bit = 1)
Message_Filter_Restore = 0b11111011   # filtro com 11111011 -> retirar da lixeira (3o bit = 0)

# Tipos de perfil
Profile_Type_No_Type            = 0
Profile_Type_Basic              = 0b00000001  # (1o bit = 1)
Profile_Type_Class_Responsible  = 0b00000010  # (2o bit = 1)
Profile_Type_Student            = 0b00000100  # (3o bit = 1)

# Contextos de abas e menus
Context_General            = 1 #Context.find_by_name('general').id
Context_Curriculum_Unit    = 2 #Context.find_by_name('curriculum_unit').id

# Tempo extra, em dias, para o responsável poder postar no fórum
Forum_Responsible_Extra_Time = 3

Discussion_Post_Max_Indent_Level = 4
