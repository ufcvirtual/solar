puts "Development Seed"

puts "Criando registros de usuarios"

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

# courses
[
	{:id => 1,  :name => 'Letras Portugues', :code => 'LLPT' },
	{:id => 2,  :name => 'Licenciatura em Quimica', :code => 'LQUIM' }
].each do |course|
    Course.create course do |c|
      c.id = course[:id]
    end
end

enrollments = Enrollment.create([
	{:offers_id => 1, :start => '2011-01-01', :end => '2021-03-02'},
	{:offers_id => 2, :start => '2011-01-01', :end => '2021-03-02'},
	{:offers_id => 3, :start => '2011-01-01', :end => '2021-03-02'},
  {:offers_id => 4, :start => '2011-01-01', :end => '2021-03-02'},
  {:offers_id => 5, :start => '2011-01-01', :end => '2021-03-02'}
])

allocations = Allocation.create([
	{:users_id => 1, :allocation_tags_id => 1, :profiles_id => 1, :status => 1},
	{:users_id => 1, :allocation_tags_id => 2, :profiles_id => 1, :status => 1},
	{:users_id => 1, :allocation_tags_id => 3, :profiles_id => 1, :status => 1},
  {:users_id => 1, :allocation_tags_id => 8, :profiles_id => 1, :status => 0},

	{:users_id => aluno1.id, :allocation_tags_id => 1, :profiles_id => 1, :status => 1},
	{:users_id => aluno1.id, :allocation_tags_id => 2, :profiles_id => 1, :status => 1},
	{:users_id => aluno1.id, :allocation_tags_id => 3, :profiles_id => 1, :status => 1},

	{:users_id => aluno2.id, :allocation_tags_id => 1, :profiles_id => 1, :status => 1},
	{:users_id => aluno2.id, :allocation_tags_id => 2, :profiles_id => 1, :status => 1},
	{:users_id => aluno2.id, :allocation_tags_id => 3, :profiles_id => 1, :status => 1},

	{:users_id => aluno3.id, :allocation_tags_id => 1, :profiles_id => 1, :status => 1},
	{:users_id => aluno3.id, :allocation_tags_id => 2, :profiles_id => 1, :status => 1},
	{:users_id => aluno3.id, :allocation_tags_id => 3, :profiles_id => 1, :status => 1},

	{:users_id => tutor.id, :allocation_tags_id => 2, :profiles_id => 3, :status => 1},
	{:users_id => tutor.id, :allocation_tags_id => 3, :profiles_id => 3, :status => 1},

	{:users_id => tutor_presencial.id, :allocation_tags_id => 2, :profiles_id => 4, :status => 1},
	{:users_id => tutor_presencial.id, :allocation_tags_id => 3, :profiles_id => 4, :status => 1},

	{:users_id => prof.id, :allocation_tags_id => 4, :profiles_id => 2, :status => 1},
	{:users_id => prof.id, :allocation_tags_id => 5, :profiles_id => 2, :status => 1},
	{:users_id => prof.id, :allocation_tags_id => 6, :profiles_id => 2, :status => 1},

	{:users_id => coordenador_disciplina.id, :allocation_tags_id => 8, :profiles_id => 5, :status => 1}
])
