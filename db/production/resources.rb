# criando os recursos
resources_arr = [
  {:id => 1, :controller => 'users', :action => 'create', :description => 'Incluir novos usuarios no sistema'},
  {:id => 2, :controller => 'users', :action => 'update', :description => 'Alteracao dos dados do usuario'},
  {:id => 3, :controller => 'users', :action => 'mysolar', :description => 'Lista dos Portlest/Pagina inicial'},
  {:id => 4, :controller => 'users', :action => 'update_photo', :description => 'Trocar foto'},
  {:id => 5, :controller => 'users', :action => 'pwd_recovery', :description => 'Recuperar senha'},

  {:id => 6, :controller => 'offers', :action => 'show', :description => 'Visualizacao de ofertas'},
  {:id => 7, :controller => 'offers', :action => 'update', :description => 'Edicao de ofertas'},
  {:id => 8, :controller => 'offers', :action => 'showoffersbyuser', :description => 'Exibe oferta atraves de busca'},

  {:id => 9, :controller => 'groups', :action => 'show', :description => 'Visualizar turmas'},
  {:id => 10, :controller => 'groups', :action => 'update', :description => 'Editar turmas'},

  {:id => 11, :controller => 'curriculum_units', :action => 'show', :description => 'Acessar Unidade Curricular'},
  {:id => 12, :controller => 'curriculum_units', :action => 'participants', :description => 'Listar participantes de uma Unidade Curricular'},
  {:id => 13, :controller => 'curriculum_units', :action => 'informations', :description => 'Listar informacoes de uma Unidade Curricular'},

  {:id => 14, :controller => 'allocations', :action => 'cancel', :description => 'Cancelar matricula'},
  {:id => 15, :controller => 'allocations', :action => 'reactivate', :description => 'Pedir reativacao de matricula'},
  {:id => 16, :controller => 'allocations', :action => 'send_request', :description => 'Pedir matricula'},
  {:id => 17, :controller => 'allocations', :action => 'cancel_request', :description => 'Cancelar pedido de matricula'},

  {:id => 18, :controller => 'lessons', :action => 'show', :description => 'Ver aula'},
  {:id => 19, :controller => 'lessons', :action => 'list', :description => 'Listar aulas de uma Unidade Curricular'},
  {:id => 20, :controller => 'lessons', :action => 'show_header', :description => 'Ver aula - header'},
  {:id => 21, :controller => 'lessons', :action => 'show_content', :description => 'Ver aula - content'},

  {:id => 22, :controller => 'discussions', :action => 'list', :description => 'Listar Foruns'},
  {:id => 23, :controller => 'bibliography', :action =>'list', :description => 'Bibliografia do curso'},

  {:id => 24, :controller => 'portfolio', :action =>'list', :description => 'Portfolio da Unidade Curricular'},
  {:id => 25, :controller => 'messages', :action =>'index', :description => 'Mensagens'},
  {:id => 26, :controller => 'schedules', :action =>'list', :description => 'Agenda'},

  {:id => 27, :controller => 'portfolio', :action => 'activity_details', :description => 'Atividades Individuais'},
  {:id => 28, :controller => 'portfolio', :action => 'delete_file_individual_area', :description => 'Delecao de arquivos da area privada'},
  {:id => 29, :controller => 'portfolio', :action => 'delete_file_public_area', :description => 'Delecao de arquivos da area publica'},
  {:id => 30, :controller => 'portfolio', :action => 'download_file_comment', :description => 'Download de arquivos enviados pelo professor'},
  {:id => 31, :controller => 'portfolio', :action => 'upload_files_public_area', :description => 'Upload de arquivos para a area publica'},
  {:id => 32, :controller => 'portfolio', :action => 'download_file_public_area', :description => 'Download de arquivos da area publica'},
  {:id => 33, :controller => 'portfolio', :action => 'upload_files_individual_area', :description => 'Upload de arquivos para a area privada'},
  {:id => 34, :controller => 'portfolio', :action => 'download_file_individual_area', :description => 'Download de arquivos da area privada'},

  {:id => 35, :controller => 'portfolio_teacher', :action => 'list', :description => 'Lista os alunos da turma'},
  {:id => 36, :controller => 'portfolio_teacher', :action => 'student_detail', :description => 'Detalha portfolio do aluno'},
  {:id => 37, :controller => 'portfolio_teacher', :action => 'update_comment', :description => 'Comentar atividade do aluno'},
  {:id => 38, :controller => 'portfolio_teacher', :action => 'delete_file', :description => 'Deletar arquivos de comentarios'},
  {:id => 39, :controller => 'portfolio_teacher', :action => 'upload_files', :description => 'Upload de arquivos de correcao'},
  {:id => 40, :controller => 'portfolio_teacher', :action => 'download_files_student', :description => 'Download de arquivos enviados pelo aluno'},

  # Discussion deve ser separado em dois controllers: Discussion e Discussion_post#
  {:id => 42, :controller => 'discussions', :action => 'new_post', :description => 'Cria um novo post'},
  {:id => 43, :controller => 'discussions', :action => 'remove_post', :description => 'Remove um post'},
  {:id => 44, :controller => 'discussions', :action => 'update_post', :description => 'Atualiza o conteudo de um post'},
  {:id => 45, :controller => 'discussions', :action => 'show', :description => 'Exibe todos os posts'},
  {:id => 46, :controller => 'discussions', :action => 'list', :description => 'Lista os foruns'},

  # acompanhamento
  {:id => 47, :controller => 'scores', :action => 'show', :description => 'Exibicao dos dados do aluno'},

  # acompanhamento do professor
  {:id => 48, :controller => 'scores_teacher', :action => 'list', :description => 'Lista dos alunos da turma'},
  {:id => 49, :controller => 'discussions', :action => 'download_post_file', :description => 'Baixar arquivos de foruns'},
  {:id => 50, :controller => 'discussions', :action => 'attach_file', :description => 'Anexar arquivos de foruns'},
  {:id => 51, :controller => 'discussions', :action => 'remove_attached_file', :description => 'Remover arquivos de postagens'},
  {:id => 52, :controller => 'users', :action => 'find', :description => 'Consultar dados do usuario'},
  {:id => 53, :controller => 'discussions', :action => 'post_file_upload', :description => 'Exibir janela para upload de arquivos no foruns'},

  # Material de apoio
  {:id => 54, :controller => 'support_material_file', :action => 'list_visualization', :description => 'Visualizar material de apoio'},
  {:id => 55, :controller => 'support_material_file', :action => 'download', :description => 'Baixar um arquivo de material de apoio'},
  {:id => 56, :controller => 'support_material_file', :action => 'download_all_file_ziped', :description => 'Baixar todos os arquivos de material de apoio ZIPADO'},
  {:id => 57, :controller => 'support_material_file', :action => 'download_folder_file_ziped', :description => 'Baixar arquivos de uma pasta do material de apoio ZIPADO'},

  #curso
  {:id => 58, :controller => 'courses', :action => 'create', :description => 'Criar novo curso'},
  {:id => 59, :controller => 'courses', :action => 'update', :description => 'Editar um curso'},
  {:id => 60, :controller => 'courses', :action => 'show', :description => 'Mostrar um curso'},
  {:id => 61, :controller => 'courses', :action => 'index', :description => 'inicio'},
  {:id => 62, :controller => 'courses', :action => 'destroy', :description => 'Apaga um curso'},

  # Material de apoio - editor
  {:id => 63, :controller => 'support_material_file', :action => 'list_edition', :description => 'Visulalizar arquivos do material de apoio do editor'},
  {:id => 64, :controller => 'support_material_file', :action => 'select_action_link', :description => 'Envia para o metodo de adicionar ou excluir links do material de apoio do editor'},
  {:id => 65, :controller => 'support_material_file', :action => 'select_action_file', :description => 'Envia para o metodo de adicionar ou excluir arquivos ou renomeia uma pasta do material de apoio do editor'},
  {:id => 66, :controller => 'support_material_file', :action => 'folder_verify', :description => 'Metodo que cria uma pasta temporaria e envia para a pagina do material de apoio do editor para aguardar o upload de um arquivo'},
  {:id => 67, :controller => 'support_material_file', :action => 'delete_folder', :description => 'Exclui uma pasta da pagina de material de apoio do editor'},
  {:id => 68, :controller => 'support_material_file', :action => 'edit_link', :description => 'Edita um ou mais links da pagina de material de apoio do editor'},

  # Trabalho de grupo
  {:id => 69, :controller => 'group_assignment', :action => 'list', :description => 'Grupos'}
]

puts "  - Criando resources"

count = 0
resources = Resource.create(resources_arr) do |registro|
  registro.id = resources_arr[count][:id]
  count += 1
end
