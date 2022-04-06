require File.expand_path('../application', __FILE__)
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

Solar::Application.initialize!

mailer_config = YAML::load(File.open('config/mailer.yml'))

Fb_Config = YAML::load_file(File.open('config/facebook.yml'))

# configuracoes do action mailer para o gmail - porta: 465 ou 587
ActionMailer::Base.perform_deliveries   = true
# ActionMailer::Base.delivery_method      = :smtp
ActionMailer::Base.default_url_options  = mailer_config['default_url_options']
ActionMailer::Base.smtp_settings        = mailer_config['smtp_settings']

# constantes de status de matricula e pedido de matricula - table ALLOCATIONS
Allocation_Pending            = 0 # quando pede alocação(matricula) pela 1a vez
Allocation_Activated          = 1 # com alocação ativa
Allocation_Cancelled          = 2 # com alocação cancelada
Allocation_Pending_Reactivate = 3 # quando pede alocação(matricula) depois de ter sido cancelado
Allocation_Rejected           = 4 # quando pedido de matricula eh rejeitado
Allocation_Merged             = 5 # quando matricula eh oficialmente de outra turma, que foi aglutinada

# constantes de status de aula - table LESSONS
Lesson_Test      = 0 # aula em teste
Lesson_Approved  = 1 # aula aprovada

# constantes para tipo de arquivo
Material_Type_File = 0
Material_Type_Link = 1

# constantes de tipo de aula
Lesson_Type_File = 0 # aula com envio de arquivo
Lesson_Type_Link = 1 # aula por link

# constantes de tipo de trabalhos
Assignment_Type_Individual = 0
Assignment_Type_Group      = 1
Assignment_Type_Individual_Group = 2

# constantes de tipo de Prova
Exam_Type_Objective  = 0
Exam_Type_Subjective = 1

# constante que indica numero maximo de abas abertas
Max_Tabs_Open = 4

# filtros para mensagem
Message_Filter_Receiver = 0b00000000   # 00000000 -> destino   (1o bit = 0)
Message_Filter_Sender   = 0b00000001   # 00000001 -> origem    (1o bit = 1)
Message_Filter_Unread   = 0b11111101   # 11111101 -> nao lida  (2o bit = 0)
Message_Filter_Read     = 0b00000010   # 00000010 -> lida      (2o bit = 1)
Message_Filter_Restore  = 0b11111011   # 11111011 -> ñ lixeira (3o bit = 0)
Message_Filter_Trash    = 0b00000100   # 00000100 -> lixeira   (3o bit = 1)

Message_Limit_Of_Recipients = 90

# Tipos de perfil
Profile_Type_No_Type            = 0
Profile_Type_Basic              = 0b00000001  # (1o bit = 1)
Profile_Type_Class_Responsible  = 0b00000010  # (2o bit = 1)
Profile_Type_Student            = 0b00000100  # (3o bit = 1)
Profile_Type_Editor             = 0b00001000  # (4o bit = 1)
Profile_Type_Admin              = 0b00010000  # (5o bit = 1)
Profile_Type_Observer           = 0b00100000  # (6o bit = 1)
Profile_Type_Coord              = 0b01000000  # (7o bit = 1)

# Perfis de editor inicialmente alocados ao criar
Curriculum_Unit_Initial_Profile = 5

# Contextos de abas e menus
Context_General         = 1 #Context.find_by_name('general').id
Context_Curriculum_Unit = 2 #Context.find_by_name('curriculum_unit').id

# Tempo extra, em dias, para o responsável poder executar uma ação
Discussion_Responsible_Extra_Time   = 3
Discussion_Post_Max_Indent_Level    = 7
Assignment_Responsible_Extra_Time   = 3

# Tipos de eventos
Presential_Test     = 1 # prova presencial
Presential_Meeting  = 2 # encontro presencial
Recess              = 3 # recesso
Holiday             = 4 # feriado
WebConferenceLesson = 5 # aula por web conferência
Other				= 6 # other
RemoteEvaluation    = 7 # avaliação remota

# número máximo de turmas exibidas sem expansão da div
Max_Groups_Shown_Filter = 30 # no filtro
Max_Groups_Shown_Tags 	= 15 # nas tags
