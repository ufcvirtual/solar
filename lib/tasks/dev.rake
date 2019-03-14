namespace :dev do
  desc "Setup Development"
  task setup: :environment do

    puts %x(rake db:drop)
    puts %x(rake db:create)
    puts %x(rake db:migrate)
    puts %x(rake db:seed)
  
    puts "Criando Curso..."

    curso = Course.new(name: "Ciências da Computação", code: "202")
    curso.user_id = 14
    curso.save!
    
    curso2 = Course.new(name: "Engenharia da Computação", code: "204")
    curso2.user_id = 14
    curso2.save!

    puts "Curso criado com sucesso!"  

    puts "----------------------------------------------------------------------------\n"
  
    puts "Criando Disciplina..."

    tipo = CurriculumUnitType.find_by_description("Curso de Graduacao a Distancia")
    tipo2 = CurriculumUnitType.find_by_description("Curso de Graduacao Presencial")

    disciplina = CurriculumUnit.new(name: "Lógica de Programação", curriculum_unit_type_id: tipo.id, code: "LP203", resume: "curso de programação", objectives: "aprender programação", syllabus: "lógica de programação", working_hours: 30)
    disciplina2 = CurriculumUnit.new(name: "Banco de Dados", curriculum_unit_type_id: tipo.id, code: "LP303", resume: "curso de banco de dados", objectives: "aprender banco de dados", syllabus: "banco de dados", working_hours: 30)
    
    outra_disciplina = CurriculumUnit.new(name: "Redes de Computadores", curriculum_unit_type_id: tipo2.id, code: "LP606", resume: "curso de redes", objectives: "aprender redes", syllabus: "redes", working_hours: 30)
    
    disciplina.user_id = 14
    disciplina2.user_id = 14
    outra_disciplina.user_id = 14
    
    disciplina.save!
    disciplina2.save!
    outra_disciplina.save!

    puts "Disciplina criada com sucesso!"  

    puts "----------------------------------------------------------------------------\n"
  
    puts "Criando Semestre com datas de matrícula e periodo"

    enrollment_period = Schedule.create!(start_date: Date.current, end_date: Date.current + 1.day)
    offer_period = Schedule.create!(start_date: Date.current, end_date: Date.current + 4.month)

    semester = Semester.create!(name: "2018.1", offer_schedule: offer_period, enrollment_schedule: enrollment_period)
    
    enrollment_period2 = Schedule.create!(start_date: Date.yesterday, end_date: Date.yesterday)
    offer_period2 = Schedule.create!(start_date: Date.yesterday, end_date: Date.yesterday + 4.month)

    semester2 = Semester.create!(name: "2019.1", offer_schedule: offer_period2, enrollment_schedule: enrollment_period2)

    puts "Semestre criado com sucesso!"  

    puts "----------------------------------------------------------------------------\n"
  
    puts "Criando Oferta..."

    offer = Offer.new(course_id: curso.id, curriculum_unit_id: disciplina.id, semester_id: semester.id)
    outra_offer = Offer.new(course_id: curso.id, curriculum_unit_id: disciplina2.id, semester_id: semester.id)
    
    offer.user_id = 14
    outra_offer.user_id = 14
    
    offer.save!
    outra_offer.save!
    
    offer2 = Offer.new(course_id: curso2.id, curriculum_unit_id: outra_disciplina.id, semester_id: semester2.id) #### testar aqui
    offer2.user_id = 14    
    offer2.save!

    puts "Oferta criada com sucesso!"

    puts "----------------------------------------------------------------------------\n"
  
    puts "Criando Turma..."

    turma1 = Group.new(offer_id: offer.id, code:"LP202", status: true, name: 'LP202')
    turma2 = Group.new(offer_id: offer.id, code:"LP404", status: true, name: 'LP404')

    turma3 = Group.new(offer_id: offer2.id, code:"LP602", status: true, name: 'LP602')
    
    turma1.user_id = 14
    turma2.user_id = 14
    turma3.user_id = 14
    
    turma1.save!
    turma2.save!
    turma3.save!

    puts "Turma criada com sucesso!"

    puts "--------------------------------------------------------------------------------\n"

    puts "Criando usuários..."

    for i in 4..24 do
      u = User.new(  name: "Aluno#{i}",
              nick: "aluno#{i}",
              cpf: CpfUtils.cpf,
              username: "aluno#{i}",
              email: Faker::Internet.email,
              password: "123456",
              birthdate: Date.current - "#{Random.rand(20..30)}".to_i.years
             ) 
      u.save!
    end

    u = User.new(  name: "Editor2",
        nick: "editor2",
        cpf: CpfUtils.cpf,
        username: "editor2",
        email: Faker::Internet.email,
        password: "123456",
        birthdate: Date.current - "#{Random.rand(20..30)}".to_i.years
      ) 
    u.save!
    
    puts "Usuários cadastrados com sucesso!"

    puts "--------------------------------------------------------------------------------\n"

    puts "Matriculando Usuarios na turma e disciplina criada..."

    users = User.last(19)
    turma1 = Group.find_by(code: 'LP202')
    turma2 = Group.find_by(code: 'LP404')
    turma3 = Group.find_by(code: 'LP602')

    allocation_tag_turma1 = AllocationTag.find_by(group_id: turma1.id)
    allocation_tag_turma2 = AllocationTag.find_by(group_id: turma2.id)
    allocation_tag_turma3 = AllocationTag.find_by(group_id: turma3.id)

    users[0..10].each do |u|
      Allocation.create!(user_id: u.id, allocation_tag_id: allocation_tag_turma1.id, profile_id: 1, status: 1)
    end
    
    users[11..20].each do |u|
      Allocation.create!(user_id: u.id, allocation_tag_id: allocation_tag_turma2.id, profile_id: 1, status: 1)
    end

    Allocation.create!(user_id: 23, allocation_tag_id: allocation_tag_turma3.id, profile_id: 1, status: 1)

    puts "Usuarios matriculados."

    puts "--------------------------------------------------------------------------------\n"

    puts "Definindo Usuário Professor como Professor Titular da turma criada"

    Allocation.create!(user_id: 6, allocation_tag_id: allocation_tag_turma1.id, profile_id: 2, status: 1)
    Allocation.create!(user_id: 6, allocation_tag_id: allocation_tag_turma2.id, profile_id: 2, status: 1)
    Allocation.create!(user_id: 6, allocation_tag_id: allocation_tag_turma3.id, profile_id: 2, status: 1)
    
    puts "Definindo novo Editor2"
    Allocation.create!(user_id: User.last.id, allocation_tag_id: allocation_tag_turma1.id, profile_id: 5, status: 1)
    Allocation.create!(user_id: User.last.id, allocation_tag_id: allocation_tag_turma2.id, profile_id: 5, status: 1)
    

  end

end
