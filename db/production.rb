puts "Production Seed"

curriculum_unit_types = CurriculumUnitType.create([
	{ :description => 'Curso de Graduação Presencial', :allows_enrollment => TRUE },
	{ :description => 'Curso de Graduação a Distância', :allows_enrollment => FALSE },
	{ :description => 'Curso Livre', :allows_enrollment => TRUE },
	{ :description => 'Curso de Extensão', :allows_enrollment => TRUE },
	{ :description => 'Curso de Pós-Graduação Presencial', :allows_enrollment => TRUE },
	{ :description => 'Curso de Pós-Graduação a Distância', :allows_enrollment => FALSE }
])

profiles = Profile.create([
	{:name => 'Aluno', :student => TRUE},
	{:name => 'Prof. Titular', :class_responsible => TRUE},
	{:name => 'Tutor', :class_responsible => TRUE},
	{:name => 'Tutor Presencial'}
])

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
	{:controller => 'group', :action => 'update', :description => 'Editar turmas'}
])

permissions = Permission.create([
	{:profiles_id => profiles[0].id, :resources_id => resources[5].id, :per_id => true},
	{:profiles_id => profiles[0].id, :resources_id => resources[6].id, :per_id => true},
	{:profiles_id => profiles[0].id, :resources_id => resources[7].id, :per_id => true},
	{:profiles_id => profiles[0].id, :resources_id => resources[8].id, :per_id => true},
	{:profiles_id => profiles[0].id, :resources_id => resources[9].id, :per_id => true}
])
