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

  {:id => 11, :controller => 'curriculum_units', :action => 'access', :description => 'Acessar Unidade Curricular'},
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
  {:id => 26, :controller => 'agenda', :action =>'list', :description => 'Agenda'},

  {:id => 27, :controller => 'portfolio', :action => 'activity_details', :description => 'Atividades Individuais'},
  {:id => 28, :controller => 'portfolio', :action => 'delete_file_individual_area', :description => ''},
  {:id => 29, :controller => 'portfolio', :action => 'delete_file_public_area', :description => ''},
  {:id => 30, :controller => 'portfolio', :action => 'download_file_comment', :description => ''},
  {:id => 31, :controller => 'portfolio', :action => 'upload_files_public_area', :description => ''},
  {:id => 32, :controller => 'portfolio', :action => 'download_file_public_area', :description => ''},
  {:id => 33, :controller => 'portfolio', :action => 'upload_files_individual_area', :description => ''},
  {:id => 34, :controller => 'portfolio', :action => 'download_file_individual_area', :description => ''}
]
count = 0
resources = Resource.create(resources_arr) do |registro|
  registro.id = resources_arr[count][:id]
  count += 1
end
########################
#        PERFIS        #
########################

###############
#    ALUNO    #
###############
perm_alunos = PermissionsResource.create([
  # offer
	{:profile_id => 1, :resource_id => 6, :per_id => true},
	{:profile_id => 1, :resource_id => 7, :per_id => true},
	{:profile_id => 1, :resource_id => 8, :per_id => true},
  # group
	{:profile_id => 1, :resource_id => 9, :per_id => true},
	{:profile_id => 1, :resource_id => 10, :per_id => true},
  # curriculum unit
  {:profile_id => 1, :resource_id => 11, :per_id => false},
  {:profile_id => 1, :resource_id => 12, :per_id => false},
  {:profile_id => 1, :resource_id => 13, :per_id => false},
  {:profile_id => 1, :resource_id => 14, :per_id => false},
  {:profile_id => 1, :resource_id => 15, :per_id => false},
  {:profile_id => 1, :resource_id => 16, :per_id => false},
  {:profile_id => 1, :resource_id => 17, :per_id => false},
  {:profile_id => 1, :resource_id => 18, :per_id => false},
  {:profile_id => 1, :resource_id => 19, :per_id => false},
  {:profile_id => 1, :resource_id => 20, :per_id => false},
  {:profile_id => 1, :resource_id => 21, :per_id => false},
  {:profile_id => 1, :resource_id => 22, :per_id => false},
  {:profile_id => 1, :resource_id => 23, :per_id => false},
  {:profile_id => 1, :resource_id => 24, :per_id => false},

  {:profile_id => 1, :resource_id => 27, :per_id => false},
  {:profile_id => 1, :resource_id => 28, :per_id => false},
  {:profile_id => 1, :resource_id => 29, :per_id => false},
  {:profile_id => 1, :resource_id => 30, :per_id => false},
  {:profile_id => 1, :resource_id => 31, :per_id => false},
  {:profile_id => 1, :resource_id => 32, :per_id => false},
  {:profile_id => 1, :resource_id => 33, :per_id => false},
  {:profile_id => 1, :resource_id => 34, :per_id => false}
])

##############################
#      PROFESSOR TITULAR     #
##############################
perm_prof_titular = PermissionsResource.create([
  # offer
	{:profile_id => 2, :resource_id => 6, :per_id => true},
	{:profile_id => 2, :resource_id => 7, :per_id => true},
	{:profile_id => 2, :resource_id => 8, :per_id => true},
  # group
	{:profile_id => 2, :resource_id => 9, :per_id => true},
	{:profile_id => 2, :resource_id => 10, :per_id => true},
  # curriculum unit
  {:profile_id => 2, :resource_id => 11, :per_id => false},
  {:profile_id => 2, :resource_id => 12, :per_id => false},
  {:profile_id => 2, :resource_id => 13, :per_id => false},
  {:profile_id => 2, :resource_id => 14, :per_id => false},
  {:profile_id => 2, :resource_id => 15, :per_id => false},
  {:profile_id => 2, :resource_id => 16, :per_id => false},
  {:profile_id => 2, :resource_id => 17, :per_id => false},
  {:profile_id => 2, :resource_id => 18, :per_id => false},
  {:profile_id => 2, :resource_id => 19, :per_id => false},
  {:profile_id => 2, :resource_id => 22, :per_id => false},
  {:profile_id => 2, :resource_id => 23, :per_id => false},
  {:profile_id => 2, :resource_id => 24, :per_id => false}
])

##############################
#      TUTOR A DISTANCIA     #
##############################
perm_prof_titular = PermissionsResource.create([
  # offer
	{:profile_id => 3, :resource_id => 6, :per_id => true},
	{:profile_id => 3, :resource_id => 7, :per_id => true},
	{:profile_id => 3, :resource_id => 8, :per_id => true},
  # group
	{:profile_id => 3, :resource_id => 9, :per_id => true},
	{:profile_id => 3, :resource_id => 10, :per_id => true},
  # curriculum unit
  {:profile_id => 3, :resource_id => 11, :per_id => false},
  {:profile_id => 3, :resource_id => 12, :per_id => false},
  {:profile_id => 3, :resource_id => 13, :per_id => false},
  {:profile_id => 3, :resource_id => 14, :per_id => false},
  {:profile_id => 3, :resource_id => 15, :per_id => false},
  {:profile_id => 3, :resource_id => 16, :per_id => false},
  {:profile_id => 3, :resource_id => 17, :per_id => false},
  {:profile_id => 3, :resource_id => 18, :per_id => false},
  {:profile_id => 3, :resource_id => 19, :per_id => false},
  {:profile_id => 3, :resource_id => 22, :per_id => false},
  {:profile_id => 3, :resource_id => 23, :per_id => false},
  {:profile_id => 3, :resource_id => 24, :per_id => false}
])


######## PERMISSIONS MENUS #########


PermissionsMenu.create([
    {:profile_id => 1, :menu_id => 10},
    {:profile_id => 1, :menu_id => 101},
    {:profile_id => 1, :menu_id => 20},
    {:profile_id => 1, :menu_id => 201},
    {:profile_id => 1, :menu_id => 202},
    {:profile_id => 1, :menu_id => 30},
    {:profile_id => 1, :menu_id => 301},
    {:profile_id => 1, :menu_id => 303},
    {:profile_id => 1, :menu_id => 304},
    {:profile_id => 1, :menu_id => 50},
    {:profile_id => 1, :menu_id => 70},
    {:profile_id => 1, :menu_id => 302},

    {:profile_id => 2, :menu_id => 10},
    {:profile_id => 2, :menu_id => 101},
    {:profile_id => 2, :menu_id => 20},
    {:profile_id => 2, :menu_id => 201},
    {:profile_id => 2, :menu_id => 202},
    {:profile_id => 2, :menu_id => 30},
    {:profile_id => 2, :menu_id => 301},
    {:profile_id => 2, :menu_id => 303},
    {:profile_id => 2, :menu_id => 304},
    {:profile_id => 2, :menu_id => 50},
    {:profile_id => 2, :menu_id => 70},
    {:profile_id => 2, :menu_id => 302},

    {:profile_id => 3, :menu_id => 10},
    {:profile_id => 3, :menu_id => 101},
    {:profile_id => 3, :menu_id => 20},
    {:profile_id => 3, :menu_id => 201},
    {:profile_id => 3, :menu_id => 202},
    {:profile_id => 3, :menu_id => 30},
    {:profile_id => 3, :menu_id => 301},
    {:profile_id => 3, :menu_id => 303},
    {:profile_id => 3, :menu_id => 304},
    {:profile_id => 3, :menu_id => 50},
    {:profile_id => 3, :menu_id => 70},
    {:profile_id => 3, :menu_id => 302}
])