puts "Criando permissoes para os perfis"

# criando os recursos
resources = Resource.create([
	{:controller => 'user', :action => 'create', :description => 'Incluir novos usuarios no sistema'},
	{:controller => 'user', :action => 'update', :description => 'Alteracao dos dados do usuario'},
	{:controller => 'user', :action => 'mysolar', :description => 'Lista dos Portlest/Pagina inicial'},
	{:controller => 'user', :action => 'update_photo', :description => 'Trocar foto'},
	{:controller => 'user', :action => 'pwd_recovery', :description => 'Recuperar Senha'},
	{:controller => 'offer', :action => 'show', :description => 'Visualizacao de ofertas'},
	{:controller => 'offer', :action => 'update', :description => 'Edicao de ofertas'},
	{:controller => 'offer', :action => 'showoffersbyuser', :description => 'Exibe oferta atraves de busca'},
	{:controller => 'group', :action => 'show', :description => 'Visualizar turmas'},
	{:controller => 'group', :action => 'update', :description => 'Editar turmas'},
#10
  {:controller => 'curriculum_unit', :action => 'access', :description => 'Acessar Unidade Curricular'},
  {:controller => 'curriculum_unit', :action => 'participants', :description => 'Listar Participantes de uma Unidade Curricular'},
  {:controller => 'curriculum_unit', :action => 'informations', :description => 'Listar Informacoes de uma Unidade Curricular'},
#13
  {:controller => 'allocation', :action => 'cancel', :description => 'Cancelar Matricula'},
  {:controller => 'allocation', :action => 'reactivate', :description => 'Pedir Reativacao de Matricula'},
  {:controller => 'allocation', :action => 'send_request', :description => 'Pedir Matricula'},
  {:controller => 'allocation', :action => 'cancel_request', :description => 'Cancelar Pedido de Matricula'}
#  {:controller => '', :action => '', :description => ''},

])

########################
#        PERFIS        #
########################

# perfil aluno
perm_alunos = Permission.create([
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

# professor titular
perm_prof_titular = Permission.create([
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

# tutor a distancia
perm_prof_titular = Permission.create([
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
