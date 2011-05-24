# criando os recursos
resources_arr = [
	{:controller => 'users', :action => 'create', :description => 'Incluir novos usuarios no sistema'},
	{:controller => 'users', :action => 'update', :description => 'Alteracao dos dados do usuario'},
	{:controller => 'users', :action => 'mysolar', :description => 'Lista dos Portlest/Pagina inicial'},
	{:controller => 'users', :action => 'update_photo', :description => 'Trocar foto'},
	{:controller => 'users', :action => 'pwd_recovery', :description => 'Recuperar senha'},
#5
	{:controller => 'offers', :action => 'show', :description => 'Visualizacao de ofertas'},
	{:controller => 'offers', :action => 'update', :description => 'Edicao de ofertas'},
	{:controller => 'offers', :action => 'showoffersbyuser', :description => 'Exibe oferta atraves de busca'},
#8
	{:controller => 'groups', :action => 'show', :description => 'Visualizar turmas'},
	{:controller => 'groups', :action => 'update', :description => 'Editar turmas'},
#10
  {:controller => 'curriculum_units', :action => 'access', :description => 'Acessar Unidade Curricular'},
  {:controller => 'curriculum_units', :action => 'participants', :description => 'Listar participantes de uma Unidade Curricular'},
  {:controller => 'curriculum_units', :action => 'informations', :description => 'Listar informacoes de uma Unidade Curricular'},
#13
  {:controller => 'allocations', :action => 'cancel', :description => 'Cancelar matricula'},
  {:controller => 'allocations', :action => 'reactivate', :description => 'Pedir reativacao de matricula'},
  {:controller => 'allocations', :action => 'send_request', :description => 'Pedir matricula'},
  {:controller => 'allocations', :action => 'cancel_request', :description => 'Cancelar pedido de matricula'},
#17
  {:controller => 'lessons', :action => 'show', :description => 'Ver aula'},
  {:controller => 'lessons', :action => 'list', :description => 'Listar aulas de uma Unidade Curricular'},
  {:controller => 'lessons', :action => 'show_header', :description => 'Ver aula - header'},
  {:controller => 'lessons', :action => 'show_content', :description => 'Ver aula - content'},
#  {:controller => '', :action => '', :description => ''},
#21
  {:controller => 'discussions', :action => 'list', :description => 'Listar Foruns'}
]
count = 1
resources = Resource.create(resources_arr) do |registro|
  registro.id = count
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
	{:profiles_id => 1, :resources_id => resources[5].id, :per_id => true},
	{:profiles_id => 1, :resources_id => resources[6].id, :per_id => true},
	{:profiles_id => 1, :resources_id => resources[7].id, :per_id => true},
  # group
	{:profiles_id => 1, :resources_id => resources[8].id, :per_id => true},
	{:profiles_id => 1, :resources_id => resources[9].id, :per_id => true},
  # curriculum unit
  {:profiles_id => 1, :resources_id => resources[10].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[11].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[12].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[13].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[14].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[15].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[16].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[17].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[18].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[19].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[20].id, :per_id => false},
  {:profiles_id => 1, :resources_id => resources[21].id, :per_id => false}
])

##############################
#      PROFESSOR TITULAR     #
##############################
perm_prof_titular = PermissionsResource.create([
  # offer
	{:profiles_id => 2, :resources_id => resources[5].id, :per_id => true},
	{:profiles_id => 2, :resources_id => resources[6].id, :per_id => true},
	{:profiles_id => 2, :resources_id => resources[7].id, :per_id => true},
  # group
	{:profiles_id => 2, :resources_id => resources[8].id, :per_id => true},
	{:profiles_id => 2, :resources_id => resources[9].id, :per_id => true},
  # curriculum unit
  {:profiles_id => 2, :resources_id => resources[10].id, :per_id => false},
  {:profiles_id => 2, :resources_id => resources[11].id, :per_id => false},
  {:profiles_id => 2, :resources_id => resources[12].id, :per_id => false},
  {:profiles_id => 2, :resources_id => resources[13].id, :per_id => false},
  {:profiles_id => 2, :resources_id => resources[14].id, :per_id => false},
  {:profiles_id => 2, :resources_id => resources[15].id, :per_id => false},
  {:profiles_id => 2, :resources_id => resources[16].id, :per_id => false},
  {:profiles_id => 2, :resources_id => resources[17].id, :per_id => false},
  {:profiles_id => 2, :resources_id => resources[18].id, :per_id => false},
  {:profiles_id => 2, :resources_id => resources[21].id, :per_id => false}
])

##############################
#      TUTOR A DISTANCIA     #
##############################
perm_prof_titular = PermissionsResource.create([
  # offer
	{:profiles_id => 3, :resources_id => resources[5].id, :per_id => true},
	{:profiles_id => 3, :resources_id => resources[6].id, :per_id => true},
	{:profiles_id => 3, :resources_id => resources[7].id, :per_id => true},
  # group
	{:profiles_id => 3, :resources_id => resources[8].id, :per_id => true},
	{:profiles_id => 3, :resources_id => resources[9].id, :per_id => true},
  # curriculum unit
  {:profiles_id => 3, :resources_id => resources[10].id, :per_id => false},
  {:profiles_id => 3, :resources_id => resources[11].id, :per_id => false},
  {:profiles_id => 3, :resources_id => resources[12].id, :per_id => false},
  {:profiles_id => 3, :resources_id => resources[13].id, :per_id => false},
  {:profiles_id => 3, :resources_id => resources[14].id, :per_id => false},
  {:profiles_id => 3, :resources_id => resources[15].id, :per_id => false},
  {:profiles_id => 3, :resources_id => resources[16].id, :per_id => false},
  {:profiles_id => 3, :resources_id => resources[17].id, :per_id => false},
  {:profiles_id => 3, :resources_id => resources[18].id, :per_id => false},
  {:profiles_id => 3, :resources_id => resources[21].id, :per_id => false}
])


######## PERMISSIONS MENUS #########


PermissionsMenu.create([
    {:profiles_id => 1, :menus_id => 10},
    {:profiles_id => 1, :menus_id => 101},
    {:profiles_id => 1, :menus_id => 20},
    {:profiles_id => 1, :menus_id => 201},
    {:profiles_id => 1, :menus_id => 30},
    {:profiles_id => 1, :menus_id => 301},
    {:profiles_id => 1, :menus_id => 304},
    {:profiles_id => 1, :menus_id => 50},
    {:profiles_id => 1, :menus_id => 70},

    {:profiles_id => 2, :menus_id => 10},
    {:profiles_id => 2, :menus_id => 101},
    {:profiles_id => 2, :menus_id => 20},
    {:profiles_id => 2, :menus_id => 201},
    {:profiles_id => 2, :menus_id => 30},
    {:profiles_id => 2, :menus_id => 301},
    {:profiles_id => 2, :menus_id => 304},
    {:profiles_id => 2, :menus_id => 50},
    {:profiles_id => 2, :menus_id => 70},

    {:profiles_id => 3, :menus_id => 10},
    {:profiles_id => 3, :menus_id => 101},
    {:profiles_id => 3, :menus_id => 20},
    {:profiles_id => 3, :menus_id => 201},
    {:profiles_id => 3, :menus_id => 30},
    {:profiles_id => 3, :menus_id => 301},
    {:profiles_id => 3, :menus_id => 304},
    {:profiles_id => 3, :menus_id => 50},
    {:profiles_id => 3, :menus_id => 70},


])