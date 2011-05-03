require 'active_record/fixtures.rb'

puts "Development Seed"

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

puts "  - Executando fixture: #{fixtures}"

Fixtures.create_fixtures(fixtures_folder, fixtures)

puts "Criando registros de usuarios"

user1 = User.new :login => 'user', :email => 'user@solar.ufc.br', :name => 'Usuario do Sistema', :cpf => '78218921494', :birthdate => '2005-03-02', :gender => true, :address => 'em algum lugar', :address_number => 58, :address_neighborhood => 'bons', :country => 'brazil', :state => 'CE', :city => 'fortaleza', :institution => 'ufc', :zipcode => '60450170'
user1.password = 'user123'
user1.save

prof = User.new :login => 'prof', :email => 'prof@solar.ufc.br', :name => 'Professor', :cpf => '21872285848', :birthdate => '2000-03-02', :gender => true, :address => 'em algum lugar', :address_number => 58, :address_neighborhood => 'bons', :country => 'brazil', :state => 'CE', :city => 'fortaleza', :institution => 'ufc', :zipcode => '60450170'
prof.password = '123456'
prof.save

aluno1 = User.new :login => 'aluno1', :email => 'aluno1@solar.ufc.br', :name => 'Aluno 1', :cpf => '32305605153', :birthdate => '2006-03-02', :gender => true, :address => 'em algum lugar', :address_number => 58, :address_neighborhood => 'bons', :country => 'brazil', :state => 'CE', :city => 'fortaleza', :institution => 'ufc', :zipcode => '60450170'
aluno1.password = '123456'
aluno1.save

aluno2 = User.new :login => 'aluno2', :email => 'aluno2@solar.ufc.br', :name => 'Aluno 2', :cpf => '98447432904', :birthdate => '2004-03-02', :gender => true, :address => 'em algum lugar', :address_number => 58, :address_neighborhood => 'bons', :country => 'brazil', :state => 'CE', :city => 'fortaleza', :institution => 'ufc', :zipcode => '60450170'
aluno2.password = '123456'
aluno2.save

aluno3 = User.new :login => 'aluno3', :email => 'aluno3@solar.ufc.br', :name => 'Aluno 3', :cpf => '47382348113', :birthdate => '2002-03-02', :gender => true, :address => 'em algum lugar', :address_number => 58, :address_neighborhood => 'bons', :country => 'brazil', :state => 'CE', :city => 'fortaleza', :institution => 'ufc', :zipcode => '60450170'
aluno3.password = '123456'
aluno3.save

tutor_presencial = User.new :login => 'tutorp', :email => 'tutorp@solar.ufc.br', :name => 'Tutor Presencial', :cpf => '31877336203', :birthdate => '2000-03-02', :gender => true, :address => 'em algum lugar', :address_number => 58, :address_neighborhood => 'bons', :country => 'brazil', :state => 'CE', :city => 'fortaleza', :institution => 'ufc', :zipcode => '60450170'
tutor_presencial.password = '123456'
tutor_presencial.save

tutor = User.new :login => 'tutordist', :email => 'tutordist@solar.ufc.br', :name => 'Tutor Dist', :cpf => '10145734595', :birthdate => '2000-03-02', :gender => true, :address => 'em algum lugar', :address_number => 58, :address_neighborhood => 'bons', :country => 'brazil', :state => 'CE', :city => 'fortaleza', :institution => 'ufc', :zipcode => '60450170'
tutor.password = '123456'
tutor.save

coordenador_disciplina = User.new :login => 'coorddisc', :email => 'coord@solar.ufc.br', :name => 'Coordenador', :cpf => '04982281505', :birthdate => '2000-03-02', :gender => true, :address => 'em algum lugar', :address_number => 58, :address_neighborhood => 'bons', :country => 'brazil', :state => 'CE', :city => 'fortaleza', :institution => 'ufc', :zipcode => '60450170'
coordenador_disciplina.password = '123456'
coordenador_disciplina.save

puts "Criando cursos"

courses = Course.create([
	{ :name => 'Letras Portugues', :code => 'LLPT' },
	{ :name => 'Licenciatura em Quimica', :code => 'LQUIM' }
])

#curriculum_unit_types = CurriculumUnitType.create([
#	{ :description => 'Curso de Graduacao Presencial', :allows_enrollment => TRUE, :icon_name => 'icon_type_pres_underg.png' },
#	{ :description => 'Curso de Graduacao a Distancia', :allows_enrollment => FALSE, :icon_name => 'icon_type_dist_underg.png' },
#	{ :description => 'Curso Livre', :allows_enrollment => TRUE, :icon_name => 'icon_type_free_course.png' },
#	{ :description => 'Curso de Extensao', :allows_enrollment => TRUE, :icon_name => 'icon_type_ext_course.png' },
#	{ :description => 'Curso de Pos-Graduacao Presencial', :allows_enrollment => TRUE, :icon_name => 'icon_type_pres_grad.png' },
#	{ :description => 'Curso de Pos-Graduacao a Distancia', :allows_enrollment => FALSE, :icon_name => 'icon_type_dist_grad.png' }
#])

#resume = 'Pensando mais a longo prazo, a percepo das dificuldades nao causa impacto indireto na reavaliacao da formula da ressonancia racionalista.'
#objectives = 'Do mesmo modo, a indeterminao contnua de distintas formas de fenmeno...'
#prerequisites = 'Todavia, a consolidacao das estruturas psico-lgicas assume...'
#syllabus = 'Como Deleuze eloquentemente mostrou, o inicio da atividade geral de formacao de conceitos obstaculiza a apreciacao da importancia dos paradigmas filosoficos. '
#passing_grade = 7.0
#
#curriculum_units = CurriculumUnit.create([
#	{:curriculum_unit_types_id => 3, :name => 'Introducao a Linguistica', :code => 'RM404', :resume => resume, :objectives => objectives, :prerequisites => prerequisites, :syllabus => syllabus, :passing_grade => passing_grade},
#	{:curriculum_unit_types_id => 1, :name => 'Teoria da Literatura I', :code => 'RM405', :resume => resume, :objectives => objectives, :prerequisites => prerequisites, :syllabus => syllabus, :passing_grade => passing_grade},
#	{:curriculum_unit_types_id => 2, :name => 'Quimica I', :code => 'RM301', :resume => resume, :objectives => objectives, :prerequisites => prerequisites, :syllabus => syllabus, :passing_grade => passing_grade},
#	{:curriculum_unit_types_id => 2, :name => 'Semipresencial sm nvista', :code => 'TS101', :resume => resume, :objectives => objectives, :prerequisites => prerequisites, :syllabus => syllabus, :passing_grade => passing_grade}
#])

offers = Offer.create([
	{:curriculum_units_id => 3, :courses_id => courses[0].id, :semester => '2011.1', :start => '2011-02-01', :end => '2021-03-30'},
	{:curriculum_units_id => 2, :courses_id => courses[0].id, :semester => '2011.1', :start => '2011-03-10', :end => '2021-04-01'},
	{:curriculum_units_id => 4, :courses_id => courses[1].id, :semester => '2011.1', :start => '2011-03-10', :end => '2021-04-01'}
])

enrollments = Enrollment.create([
	{:offers_id => offers[0].id, :start => '2011-01-01', :end => '2021-03-02'},
	{:offers_id => offers[1].id, :start => '2011-01-01', :end => '2021-03-02'},
	{:offers_id => offers[2].id, :start => '2011-01-01', :end => '2021-03-02'}
])

groups = Group.create([
	{:offers_id => offers[0].id, :code => 'FOR', :status => TRUE},
	{:offers_id => offers[1].id, :code => 'CAU-A', :status => TRUE},
	{:offers_id => offers[2].id, :code => 'CAU-B', :status => TRUE}
])

profiles = Profile.create([
	{:name => 'Aluno', :student => TRUE},
	{:name => 'Prof. Titular', :class_responsible => TRUE},
	{:name => 'Tutor', :class_responsible => TRUE},
	{:name => 'Tutor Presencial'},
	{:name => 'Coordenador de Disciplina'}
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
	{:profiles_id => profiles[0].id, :resources_id => resources[5].id, :per_id => true},
	{:profiles_id => profiles[0].id, :resources_id => resources[6].id, :per_id => true},
	{:profiles_id => profiles[0].id, :resources_id => resources[7].id, :per_id => true},
	{:profiles_id => profiles[0].id, :resources_id => resources[8].id, :per_id => true},
	{:profiles_id => profiles[0].id, :resources_id => resources[9].id, :per_id => true}
])

allocation_tags = AllocationTag.create([
	{:groups_id => groups[0].id},
	{:groups_id => groups[1].id},
	{:groups_id => groups[2].id},
	{:offers_id => offers[0].id},
	{:offers_id => offers[1].id},
	{:offers_id => offers[2].id},
	{:curriculum_units_id => 1},
	{:curriculum_units_id => 1}
])

allocations = Allocation.create([
	{:users_id => user1.id, :allocation_tags_id => allocation_tags[0].id, :profiles_id => profiles[0].id, :status => 1},
	{:users_id => user1.id, :allocation_tags_id => allocation_tags[1].id, :profiles_id => profiles[0].id, :status => 1},
	{:users_id => user1.id, :allocation_tags_id => allocation_tags[2].id, :profiles_id => profiles[0].id, :status => 1},

	{:users_id => aluno1.id, :allocation_tags_id => allocation_tags[0].id, :profiles_id => profiles[0].id, :status => 1},
	{:users_id => aluno1.id, :allocation_tags_id => allocation_tags[1].id, :profiles_id => profiles[0].id, :status => 1},
	{:users_id => aluno1.id, :allocation_tags_id => allocation_tags[2].id, :profiles_id => profiles[0].id, :status => 1},

	{:users_id => aluno2.id, :allocation_tags_id => allocation_tags[0].id, :profiles_id => profiles[0].id, :status => 1},
	{:users_id => aluno2.id, :allocation_tags_id => allocation_tags[1].id, :profiles_id => profiles[0].id, :status => 1},
	{:users_id => aluno2.id, :allocation_tags_id => allocation_tags[2].id, :profiles_id => profiles[0].id, :status => 1},

	{:users_id => aluno3.id, :allocation_tags_id => allocation_tags[0].id, :profiles_id => profiles[0].id, :status => 1},
	{:users_id => aluno3.id, :allocation_tags_id => allocation_tags[1].id, :profiles_id => profiles[0].id, :status => 1},
	{:users_id => aluno3.id, :allocation_tags_id => allocation_tags[2].id, :profiles_id => profiles[0].id, :status => 1},

	{:users_id => tutor.id, :allocation_tags_id => allocation_tags[1].id, :profiles_id => profiles[2].id, :status => 1},
	{:users_id => tutor.id, :allocation_tags_id => allocation_tags[2].id, :profiles_id => profiles[2].id, :status => 1},

	{:users_id => tutor_presencial.id, :allocation_tags_id => allocation_tags[1].id, :profiles_id => profiles[3].id, :status => 1},
	{:users_id => tutor_presencial.id, :allocation_tags_id => allocation_tags[2].id, :profiles_id => profiles[3].id, :status => 1},

	{:users_id => prof.id, :allocation_tags_id => allocation_tags[3].id, :profiles_id => profiles[1].id, :status => 1},
	{:users_id => prof.id, :allocation_tags_id => allocation_tags[4].id, :profiles_id => profiles[1].id, :status => 1},
	{:users_id => prof.id, :allocation_tags_id => allocation_tags[5].id, :profiles_id => profiles[1].id, :status => 1},

	{:users_id => coordenador_disciplina.id, :allocation_tags_id => allocation_tags[7].id, :profiles_id => profiles[4].id, :status => 1},
])
