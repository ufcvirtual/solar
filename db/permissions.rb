# criando os recursos
resources_arr = [
	{:controller => 'user', :action => 'create', :description => 'Incluir novos usuarios no sistema'},
	{:controller => 'user', :action => 'update', :description => 'Alteracao dos dados do usuario'},
	{:controller => 'user', :action => 'mysolar', :description => 'Lista dos Portlest/Pagina inicial'},
	{:controller => 'user', :action => 'update_photo', :description => 'Trocar foto'},
	{:controller => 'user', :action => 'pwd_recovery', :description => 'Recuperar senha'},
#5
	{:controller => 'offer', :action => 'show', :description => 'Visualizacao de ofertas'},
	{:controller => 'offer', :action => 'update', :description => 'Edicao de ofertas'},
	{:controller => 'offer', :action => 'showoffersbyuser', :description => 'Exibe oferta atraves de busca'},
#8
	{:controller => 'group', :action => 'show', :description => 'Visualizar turmas'},
	{:controller => 'group', :action => 'update', :description => 'Editar turmas'},
#10
  {:controller => 'curriculum_unit', :action => 'access', :description => 'Acessar Unidade Curricular'},
  {:controller => 'curriculum_unit', :action => 'participants', :description => 'Listar participantes de uma Unidade Curricular'},
  {:controller => 'curriculum_unit', :action => 'informations', :description => 'Listar informacoes de uma Unidade Curricular'},
#13
  {:controller => 'allocation', :action => 'cancel', :description => 'Cancelar matricula'},
  {:controller => 'allocation', :action => 'reactivate', :description => 'Pedir reativacao de matricula'},
  {:controller => 'allocation', :action => 'send_request', :description => 'Pedir matricula'},
  {:controller => 'allocation', :action => 'cancel_request', :description => 'Cancelar pedido de matricula'},
#17
  {:controller => 'lessons', :action => 'show', :description => 'Ver aula'},
  {:controller => 'lessons', :action => 'list', :description => 'Listar aulas de uma Unidade Curricular'}
#  {:controller => '', :action => '', :description => ''},
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
  {:profiles_id => 1, :resources_id => resources[16].id, :per_id => false}
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
  {:profiles_id => 2, :resources_id => resources[16].id, :per_id => false}
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
  {:profiles_id => 3, :resources_id => resources[16].id, :per_id => false}
])
