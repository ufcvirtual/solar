require 'active_record/fixtures.rb'

puts "Production Seed"

puts "Truncando tabelas"

Allocation.delete_all
AllocationTag.delete_all
Permission.delete_all
Resource.delete_all
Profile.delete_all
Group.delete_all
Enrollment.delete_all
Offer.delete_all
CurriculumUnit.delete_all
CurriculumUnitType.delete_all
Course.delete_all
PersonalConfiguration.delete_all
User.delete_all

puts "Executando fixtures"

Fixtures.reset_cache
fixtures_folder = File.join(::Rails.root.to_s, 'spec', 'fixtures')
fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }

puts "  - Executando fixtures: #{fixtures}"

Fixtures.create_fixtures(fixtures_folder, fixtures)

puts "Criando cursos"

#Course.create([
#	{:id => 1,  :name => 'Letras Portugues', :code => 'LLPT' },
#	{:id => 2,  :name => 'Licenciatura em Quimica', :code => 'LQUIM' }
#])

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

# novos controllers
#10
  {:controller => 'CurriculumUnit', :action => 'access', :description => 'Acessar Unidade Curricular'},
  {:controller => 'CurriculumUnit', :action => 'participants', :description => 'Listar Participantes de uma Unidade Curricular'},
  {:controller => 'CurriculumUnit', :action => 'information', :description => 'Listar Informacoes de uma Unidade Curricular'},
  {:controller => 'Allocation', :action => 'cancel', :description => 'Cancelar Matricula'},
  {:controller => 'Allocation', :action => 'reactivate', :description => 'Pedir Reativacao de Matricula'},
  {:controller => 'Allocation', :action => 'send_request', :description => 'Pedir Matricula'},
  {:controller => 'Allocation', :action => 'cancel_request', :description => 'Cancelar Pedido de Matricula'}
#  {:controller => '', :action => '', :description => ''},

])

permissions = Permission.create([
	{:profiles_id => 1, :resources_id => resources[5].id, :per_id => true},
	{:profiles_id => 1, :resources_id => resources[6].id, :per_id => true},
	{:profiles_id => 1, :resources_id => resources[7].id, :per_id => true},
	{:profiles_id => 1, :resources_id => resources[8].id, :per_id => true},
	{:profiles_id => 1, :resources_id => resources[9].id, :per_id => true}
])



#curriculum_unit_types = CurriculumUnitType.create([
#	{ :description => 'Curso de Graduacao Presencial', :allows_enrollment => TRUE, :icon_name => 'icon_type_pres_underg.png' },
#	{ :description => 'Curso de Graduacao a Distancia', :allows_enrollment => FALSE, :icon_name => 'icon_type_dist_underg.png' },
#	{ :description => 'Curso Livre', :allows_enrollment => TRUE, :icon_name => 'icon_type_free_course.png' },
#	{ :description => 'Curso de Extensao', :allows_enrollment => TRUE, :icon_name => 'icon_type_ext_course.png' },
#	{ :description => 'Curso de Pos-Graduacao Presencial', :allows_enrollment => TRUE, :icon_name => 'icon_type_pres_grad.png' },
#	{ :description => 'Curso de Pos-Graduacao a Distancia', :allows_enrollment => FALSE, :icon_name => 'icon_type_dist_grad.png' }
#])

#profiles = Profile.create([
#	{:name => 'Aluno', :student => TRUE},
#	{:name => 'Prof. Titular', :class_responsible => TRUE},
#	{:name => 'Tutor', :class_responsible => TRUE},
#	{:name => 'Tutor Presencial'}
#])

#resources = Resource.create([
#	{:controller => 'user', :action => 'create', :description => 'Incluir novos usuarios no sistema'},
#	{:controller => 'user', :action => 'update', :description => 'Alteracao dos dados do usuario'},
#	{:controller => 'user', :action => 'mysolar', :description => 'Lista dos Portlest/Pagina inicial'},
#	{:controller => 'user', :action => 'update_photo', :description => 'Trocar foto'},
#	{:controller => 'user', :action => 'pwd_recovery', :description => 'Recuperar Senha'},
#	{:controller => 'offer', :action => 'show', :description => 'Visualizacao de ofertas'},
#	{:controller => 'offer', :action => 'update', :description => 'Edicao de ofertas'},
#	{:controller => 'offer', :action => 'showoffersbyuser', :description => 'Exibe oferta atraves de busca'},
#	{:controller => 'group', :action => 'show', :description => 'Visualizar turmas'},
#	{:controller => 'group', :action => 'update', :description => 'Editar turmas'}
#])

#permissions = Permission.create([
#	{:profiles_id => profiles[0].id, :resources_id => resources[5].id, :per_id => true},
#	{:profiles_id => profiles[0].id, :resources_id => resources[6].id, :per_id => true},
#	{:profiles_id => profiles[0].id, :resources_id => resources[7].id, :per_id => true},
#	{:profiles_id => profiles[0].id, :resources_id => resources[8].id, :per_id => true},
#	{:profiles_id => profiles[0].id, :resources_id => resources[9].id, :per_id => true}
#])
