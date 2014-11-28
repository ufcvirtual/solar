require "spec_helper"

describe "Loads" do

  fixtures :all

  describe ".curriculum_units" do

    describe "editors" do

      context "with valid ip" do
        context "and existing users" do
          it {
            editors = {editores: {
              codDisciplina: "RM404",
              editores: User.where(username: %w(user3 user4)).map(&:cpf)
            }}

            expect{
              post "/api/v1/load/curriculum_units/editors", editors

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(2)
          }
        end

        context "and non existing users" do
          it {
            editors = {editores: {
              codDisciplina: "RM404",
              editores: User.where(username: %w(userDontExist user3)).map(&:cpf) #only one user exists
            }}

            expect{
              post "/api/v1/load/curriculum_units/editors", editors

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(1)
          }
        end

        context "and non existing uc" do
          it {
            editors = {editores: {
              codDisciplina: "UC01",
              editores: User.where(username: %w(user3 user4)).map(&:cpf) #only one user exists
            }}

            expect{
              post "/api/v1/load/curriculum_units/editors", editors

              response.status.should eq(404)
            }.to change{Allocation.count}.by(0)
          }
        end
      end

      context "with invalid ip" do
         it "gets a not authorized" do
          editors = {editores: {
            codDisciplina: "RM404",
            editores: User.where(username: %w(user3 user4)).map(&:cpf)
          }}
          post "/api/v1/load/curriculum_units/editors", editors, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(401)
        end
      end

    end # editors

    describe "/" do
      context "with valid ip" do
        context "and non existing curriculum_unit" do
          let!(:uc_data){ {codigo: "UC01", nome: "UC01", cargaHoraria: 80, creditos: 4} }

          subject{ -> {
            post "/api/v1/load/curriculum_units/", uc_data
          } }

          it { should change(CurriculumUnit.where(curriculum_unit_type_id: 2),:count).by(1) }
          it { should change(AllocationTag,:count).by(1) }

          it {
            post "/api/v1/load/curriculum_units/", uc_data
            response.status.should eq(201)
            response.body.should == {ok: :ok}.to_json
          }
        end

        context "and existing curriculum_unit" do
          let!(:uc_data){ {codigo: "RM404", nome: "UC01", cargaHoraria: 80, creditos: 4} }

          subject{ -> {
            post "/api/v1/load/curriculum_units/", uc_data
          } }

          it { should change(CurriculumUnit,:count).by(0) }
          it { should change(AllocationTag,:count).by(0) }

          it {
            post "/api/v1/load/curriculum_units/", uc_data

            uc = CurriculumUnit.find_by_code("RM404")
            uc.name.should eq("UC01")
            uc.working_hours.should eq(80)
            uc.credits.should eq(4)

            response.status.should eq(201)
            response.body.should == {ok: :ok}.to_json
          }
        end

        context "and missing params" do
          let!(:uc_data){ {codigo: "RM404", cargaHoraria: 80, creditos: 4} }

          subject{ -> {
            post "/api/v1/load/curriculum_units/", uc_data
          } }

          it { should change(CurriculumUnit,:count).by(0) }
          it { should change(AllocationTag,:count).by(0) }

          it {
            post "/api/v1/load/curriculum_units/", uc_data

            uc = CurriculumUnit.find_by_code("RM404")
            uc.code.should eq("RM404")

            response.status.should eq(400)
          }
        end

        context "and existing curriculum_unit changing type" do
          let!(:uc_data){ {codigo: "RM404", nome: "UC01", cargaHoraria: 80, creditos: 4, tipo: 1} }

          subject{ -> {
            post "/api/v1/load/curriculum_units/", uc_data
          } }

          it { should change(CurriculumUnit.where(curriculum_unit_type_id: 3),:count).by(-1) }
          it { should change(CurriculumUnit.where(curriculum_unit_type_id: 1),:count).by(1) }
          it { should change(AllocationTag,:count).by(0) }

          it {
            post "/api/v1/load/curriculum_units/", uc_data

            uc = CurriculumUnit.find_by_code("RM404")
            uc.name.should eq("UC01")
            uc.working_hours.should eq(80)
            uc.credits.should eq(4)

            response.status.should eq(201)
            response.body.should == {ok: :ok}.to_json
          }
        end

        context "and non existing curriculum_unit with code too big" do # code must have less than 11 characters
          let!(:uc_data){ {codigo: "UC01UC01UC01UC01UC01UC01UC01UC01UC01UC01UC01", nome: "UC01", cargaHoraria: 80, creditos: 4} }

          subject{ -> {
            post "/api/v1/load/curriculum_units/", uc_data
          } }

          it { should change(CurriculumUnit.where(curriculum_unit_type_id: 2),:count).by(1) }
          it { should change(CurriculumUnit.where(code: "UC01UC01UC01UC01UC01UC01UC01UC01UC01UC01"),:count).by(1) } # cut code to fit specified size
          it { should change(CurriculumUnit.where(code: "UC01UC01UC01UC01UC01UC01UC01UC01UC01UC01UC01"),:count).by(0) }
          it { should change(AllocationTag,:count).by(1) }

          it {
            post "/api/v1/load/curriculum_units/", uc_data
            response.status.should eq(201)
            response.body.should == {ok: :ok}.to_json
          }
        end
      end

       context "with invalid ip" do
         it "gets a not authorized" do
          post "/api/v1/load/curriculum_units/", {codigo: "RM404", nome: "UC01", cargaHoraria: 80, creditos: 4}, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(401)
        end
      end
    end # /

  end # .curriculum_units

  describe ".groups" do

    describe "/" do

      context "with valid ip" do # ip is included on list of ips with access

        context "and new semester" do
          let!(:json_data){ {turmas: {ano: "2014", periodo: "2", codDisciplina: "RM302", codigo: "T01", codGraduacao: "109",
              dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
              }} }

          subject{ -> {
            post "/api/v1/load/groups", json_data}
          }

          it {
            should change(Semester,:count).by(1)
            Semester.last.offer_schedule.start_date.to_date.should eq((Date.current + 1.day).to_date)
            Semester.last.offer_schedule.end_date.to_date.should eq((Date.current + 6.months).to_date)
          }
          it {
            should change(Offer,:count).by(1)
            Offer.last.period_schedule.should eq(nil)
          }
          it { should change(Group,:count).by(1) }
          it { should change(Allocation,:count).by(3) }

          it {
            post "/api/v1/load/groups", json_data
            response.status.should eq(201) # created
            response.body.should == {ok: :ok}.to_json
          }
        end

        context "and new semester but missing group params" do # transaction must undo all changes
          let!(:json_data){ {turmas: {ano: "2014", periodo: "2", codDisciplina: "RM302", codGraduacao: "109", # missing code
              dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
              }} }

          subject{ -> {
            post "/api/v1/load/groups", json_data}
          }

          # something happened, so undo all changes and nothing is created
          it { should change(Semester,:count).by(0) }
          it { should change(Offer,:count).by(0) }
          it { should change(Group,:count).by(0) }
          it { should change(Allocation,:count).by(0) }

          it {
            post "/api/v1/load/groups", json_data
            response.status.should eq(422)
          }
        end

        context "and dates smaller then today" do
          let!(:json_data){ {turmas: {ano: "2014", periodo: "2", codDisciplina: "RM302", codigo: "T01", codGraduacao: "109",
              dtInicio: Date.current - 1.month, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
              }} }

          subject{ -> {
            post "/api/v1/load/groups", json_data}
          }

          it {
            should change(Semester,:count).by(1)
            Semester.last.offer_schedule.start_date.to_date.should eq((Date.current - 1.month).to_date)
            Semester.last.offer_schedule.end_date.to_date.should eq((Date.current + 6.months).to_date)
          }
          it {
            should change(Offer,:count).by(1)
            Offer.last.period_schedule.should eq(nil)
          }
          it { should change(Group,:count).by(1) }
          it { should change(Allocation,:count).by(3) }

          it {
            post "/api/v1/load/groups", json_data
            response.status.should eq(201) # created
            response.body.should == {ok: :ok}.to_json
          }
        end

        context "and existing semester" do
          let!(:json_data){ {turmas: {ano: "2013", periodo: "1", codDisciplina: "RM404", codigo: "RM0121", codGraduacao: "108",
            dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
            }} }

          subject{ -> {
            post "/api/v1/load/groups", json_data}
          }

          it { should change(Semester,:count).by(0) }
          it {
            should change(Offer,:count).by(1)
            Offer.last.period_schedule.start_date.to_date.should eq((Date.current + 1.day).to_date)
            Offer.last.period_schedule.end_date.to_date.should eq((Date.current + 6.months).to_date)
          }
          it { should change(Group,:count).by(1) }
          it { should change(Allocation,:count).by(3) }

          it {
            post "/api/v1/load/groups", json_data
            response.status.should eq(201) # created
            response.body.should == {ok: :ok}.to_json
          }
        end

        context "and existing offer" do
          let!(:json_data){ {turmas: {ano: "2013", periodo: "1", codDisciplina: "RM414", codigo: "RM0121", codGraduacao: "108",
            dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
            }} }

          subject{ -> {
            post "/api/v1/load/groups", json_data}
          }

          it { should change(Semester,:count).by(0) }
          it { should change(Offer,:count).by(0) }
          it { should change(Group,:count).by(1) }
          it { should change(Allocation,:count).by(3) }

          it {
            post "/api/v1/load/groups", json_data
            response.status.should eq(201) # created
            response.body.should == {ok: :ok}.to_json
          }
        end

        context "and existing group" do
          let!(:json_data){ {turmas: {ano: "2011", periodo: "1", codDisciplina: "RM301", codigo: "QM-MAR", codGraduacao: "109",
            dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
            }} }

          subject{ -> {
            post "/api/v1/load/groups", json_data}
          }

          it { should change(Semester,:count).by(0) }
          it { should change(Offer,:count).by(0) }
          it { should change(Group,:count).by(0) }
          it { should change(Allocation,:count).by(3) }

          it {
            post "/api/v1/load/groups", json_data
            response.status.should eq(201) # created
            response.body.should == {ok: :ok}.to_json
          }
        end

        context "and existing disabled group" do
          let!(:json_data){ {turmas: {ano: "2011", periodo: "1", codDisciplina: "RM301", codigo: "QM-AUR", codGraduacao: "109",
            dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
            }} }

          subject{ -> {
            post "/api/v1/load/groups", json_data}
          }

          it { should change(Semester,:count).by(0) }
          it { should change(Offer,:count).by(0) }
          it { should change(Group.where(status: false),:count).by(-1) }
          it { should change(Allocation,:count).by(3) }

          it {
            post "/api/v1/load/groups", json_data
            response.status.should eq(201) # created
            response.body.should == {ok: :ok}.to_json
          }
        end

        context "and existing group cancelling previous professor allocation" do
          let!(:json_data){ {turmas: {ano: "2011", periodo: "1", codDisciplina: "RM301", codigo: "QM-CAU", codGraduacao: "109",
            dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "31877336203"] # prof já está alocado, ele deve ser cancelado
            }} }

          subject{ -> {
            post "/api/v1/load/groups", json_data}
          }

          it { should change(Semester,:count).by(0) }
          it { should change(Offer,:count).by(0) }
          it { should change(Group,:count).by(0) }
          it { should change(Allocation,:count).by(2) }
          it { should change(User.find_by_cpf("21872285848").allocations.where(status: 1),:count).by(-1) } # remove existent allocation if user it isn't on cpf list

          it {
            post "/api/v1/load/groups", json_data
            response.status.should eq(201) # created
            response.body.should == {ok: :ok}.to_json
          }
        end

        context "and non existing uc" do
          let!(:json_data){ {turmas: {ano: "2011", periodo: "1", codDisciplina: "UC01", codigo: "QM-MAR", codGraduacao: "109",
            dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
            }} }

          subject{ -> {
            post "/api/v1/load/groups", json_data}
          }

          it { should change(Semester,:count).by(0) }
          it { should change(Offer,:count).by(0) }
          it { should change(Group,:count).by(0) }
          it { should change(Allocation,:count).by(0) }

          it {
            post "/api/v1/load/groups", json_data
            response.status.should eq(404)
          }
        end

      end

      context "with invalid ip" do # ip isn't included on list of ips with access
        it "gets a not authorized" do
          json_data = {turmas: {ano: "2013", periodo: "1", codDisciplina: "RM404", codigo: "RM0121", codGraduacao: "108",
            dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
            }}
          post "/api/v1/load/groups", json_data, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(401)
        end
      end

    end # groups

    describe "post enrollments" do

      context "with valid ip" do

        context 'and list of existing groups' do
          let!(:json_data){
            { matriculas: {cpf: "11016853521", turmas: # user3
              %{
                [
                  {"periodo": "1", "ano": "2011", "codigo": "QM-CAU", "codDisciplina": "RM301", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "QM-MAR", "codDisciplina": "RM301", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "TL-FOR", "codDisciplina": "RM301", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "TL-FOR", "codDisciplina": "RM301", "codGraduacao": "109"}
                ]
              }
              # repetido propositalmente
            }}
          }

          it {
            expect{
              post "/api/v1/load/groups/enrollments", json_data

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(3)
          }
        end

         context 'and list of existing groups and cancelling allocation' do
          let!(:json_data){
            { matriculas: {cpf: "32305605153", turmas: # aluno1
              # ignorar código de graduação 78
              %{
                [
                  {"periodo": "1", "ano": "2011", "codigo": "QM-MAR", "codDisciplina": "RM301", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "QM-MAR", "codDisciplina": "RM301", "codGraduacao": "78"}
                ]
              }
            }}
          }
          let!(:user){User.find_by_cpf("32305605153")}
          let!(:user_allocations){user.groups(1, 1, nil, 2)}

          subject{ -> {
            post "/api/v1/load/groups/enrollments", json_data}
          }

          it { should change(user.allocations,:count).by(1) } # add one allocation
          # should change by - (the number of previous allocations (were canceled) -  the number of new allocations)
          it { should change(user.allocations.where(status: 1, profile_id: 1), :count).by(-(user_allocations.count-1)) }

          it {
            post "/api/v1/load/groups/enrollments", json_data
            response.status.should eq(201) # created
            response.body.should == {ok: :ok}.to_json
          }
        end

        context 'and list of non existing groups' do
          let!(:json_data){
            { matriculas: {cpf: "11016853521", turmas: # user3
              %{
                [
                  {"periodo": "1", "ano": "2011", "codigo": "T01", "codDisciplina": "RM301", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "T02", "codDisciplina": "RM301", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "TL-FOR", "codDisciplina": "RM301", "codGraduacao": "109"}
                ]
              }
            }}
          }

          it {
            expect{
              post "/api/v1/load/groups/enrollments", json_data

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(1)
          }
        end

        context 'and non existing uc or course' do
          let!(:json_data){
            { matriculas: {cpf: "11016853521", turmas: # user3
              %{
                [
                  {"periodo": "1", "ano": "2011", "codigo": "QM-CAU", "codDisciplina": "RM301", "codGraduacao": "C01"},
                  {"periodo": "1", "ano": "2011", "codigo": "QM-MAR", "codDisciplina": "UC01", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "TL-FOR", "codDisciplina": "RM301", "codGraduacao": "109"}
                ]
              }
            }}
          }

          it {
            expect{
              post "/api/v1/load/groups/enrollments", json_data

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(1)
          }
        end

        context 'and non existing user and gets from MA' do
          cpf = ENV['VALID_CPF']
          let!(:json_data){
            { matriculas: {cpf: cpf, turmas:
              %{
                [
                  {"periodo": "1", "ano": "2011", "codigo": "QM-CAU", "codDisciplina": "RM301", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "QM-MAR", "codDisciplina": "RM301", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "TL-FOR", "codDisciplina": "RM301", "codGraduacao": "109"}
                ]
              }
            }}
          }

          it {
            expect{
              post "/api/v1/load/groups/enrollments", json_data

              User.where(cpf: cpf).count.should eq(1)

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(4) # 1 basic + 3 student
          }
        end

        context 'and non existing user' do
          let!(:json_data){
            { matriculas: {cpf: "cpf", turmas:
              %{
                [
                  {"periodo": "1", "ano": "2011", "codigo": "QM-CAU", "codDisciplina": "RM301", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "QM-MAR", "codDisciplina": "RM301", "codGraduacao": "109"},
                  {"periodo": "1", "ano": "2011", "codigo": "TL-FOR", "codDisciplina": "RM301", "codGraduacao": "109"}
                ]
              }
            }}
          }

          it {
            expect{
              post "/api/v1/load/groups/enrollments", json_data

              response.status.should eq(404)
            }.to change{Allocation.count}.by(0)
          }
        end
      end

      context "with invalid ip" do
        it "gets a not authorized" do
          json_data = { matriculas: {cpf: "11016853521", turmas: [ # user3
                        {periodo: "1", ano: "2011", codigo: "QM-CAU", codDisciplina: "RM301", codGraduacao: "109"}
                     ]}}
          post "/api/v1/load/groups/enrollments", json_data, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(401)
        end
      end

    end # post enrollments

    describe "get enrollments" do

      context "with valid ip" do

        it "gets a list of enrolled users" do
          get "/api/v1/load/groups/enrollments", periodo: "1", ano: "2011", codTurma: "LB-CAR", codDisciplina: "RM414", codGraduacao: "109" # um aluno alocado

          user = User.find(9)
          response.status.should eq(200)
          response.body.should == [{
              nome: user.name,
              cpf: user.cpf,
              email: user.email,
              dtNascimento: user.birthdate,
              sexo: user.gender,
              telefone: user.telephone,
              celular: user.cell_phone,
              numero: user.address_number,
              cep: user.zipcode,
              bairro: user.address_neighborhood,
              estado: user.state,
              municipio: user.city,
              endereco: user.address_complement.blank? ? user.address : [user.address, user.address_complement].join(", ")
            }].to_json
        end

        it "gets an empty list of enrolled users" do
          get "/api/v1/load/groups/enrollments", periodo: "1", ano: "2011", codTurma: "SP-FOR", codDisciplina: "TS101", codGraduacao: "110" # nenhum aluno alocado
          response.status.should eq(200)
          response.body.should == [].to_json
        end

        it "gets an param error when it's missing a param" do
          get "/api/v1/load/groups/enrollments", ano: "2011", codTurma: "SP-FOR", codDisciplina: "TS101", codGraduacao: "110" # falta parâmetro
          response.status.should eq(400)
        end

        it "gets an empty array when group doesn't exsists" do
          get "/api/v1/load/groups/enrollments", periodo: "1", ano: "2011", codTurma: "S-FOR", codDisciplina: "TS101", codGraduacao: "110" # turma não existe
          response.status.should eq(404)
        end

      end

      context "with invalid ip" do
        it "gets a not authorized" do
          get "/api/v1/load/groups/enrollments", {periodo: "1", ano: "2011", codTurma: "LB-CAR", codDisciplina: "RM414", codGraduacao: "109"}, {"REMOTE_ADDR" => "127.0.0.2"}
          response.status.should eq(401)
        end
      end

    end # get enrollments

    describe "block_profile" do

      context "with valid ip" do

        context 'and list of existing groups' do
          let!(:json_data){ # user: prof, profile: tutor a distância
            { allocation: {cpf: "21872285848", perfil: 18, turma:
              {periodo: "1", ano: "2011", codigo: "QM-CAU", codDisciplina: "RM301", codGraduacao: "109"}
            }}
          }

          it {
            expect{
              put "/api/v1/load/groups/block_profile", json_data

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.where(status: 2).count}.by(1) #alocações com status cancelado aumentam de número
          }
        end

        context 'and list of non existing groups' do
          let!(:json_data){ # user: prof, profile: tutor a distância
            { allocation: {cpf: "21872285848", perfil: 18, turma:
              {periodo: "1", ano: "2011", codigo: "T02", codDisciplina: "RM301", codGraduacao: "109"}  # turma não existe
            }}
          }

          it {
            expect{
              put "/api/v1/load/groups/block_profile", json_data

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.where(status: 2).count}.by(0)
          }
        end

        context 'and non existing course' do
          let!(:json_data){ # user: prof, profile: tutor a distância
            { allocation: {cpf: "21872285848", perfil: 18, turma:
              {periodo: "1", ano: "2011", codigo: "IL-FOR", codDisciplina: "RM404", codGraduacao: "C01"}, # curso não existe
            }}
          }

          it {
            expect{
              put "/api/v1/load/groups/block_profile", json_data

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.where(status: 2).count}.by(0)
          }
        end

        context 'and non existing uc' do
          let!(:json_data){ # user: prof, profile: tutor a distância
            { allocation: {cpf: "21872285848", perfil: 18, turma:
              {periodo: "1", ano: "2011", codigo: "QM-CAU", codDisciplina: "UC01", codGraduacao: "109"}  # uc não existe
            }}
          }

          it {
            expect{
              put "/api/v1/load/groups/block_profile", json_data

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.where(status: 2).count}.by(0)
          }
        end

        context 'and non existing user' do
          let!(:json_data){ # cpf inválido
            { allocation: {cpf: "cpf", perfil: 18, turma:
              {periodo: "1", ano: "2011", codigo: "QM-CAU", codDisciplina: "RM301", codGraduacao: "109"}
            }}
          }

          it {
            expect{
              put "/api/v1/load/groups/block_profile", json_data

              response.status.should eq(404)
            }.to change{Allocation.where(status: 2).count}.by(0)
          }
        end

      end

      context "with invalid ip" do
        it "gets a not authorized" do
          json_data = # user: prof, profile: tutor a distância
            { allocation: {cpf: "21872285848", perfil: 18, turma:
              {periodo: "1", ano: "2011", codigo: "QM-CAU", codDisciplina: "RM301", codGraduacao: "109"}
            }}
          put "/api/v1/load/groups/block_profile", json_data, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(401)
        end
      end
    end #block_profile

    describe "allocate_user" do

      context "with valid ip" do

        context 'and existing user and group' do
          let!(:json_data){ # user: aluno3, profile: tutor a distância
            { allocation: { cpf: "47382348113", perfil: 18, periodo: "1", ano: "2011", codTurma: "QM-CAU", codDisciplina: "RM301", codGraduacao: "109"} }
          }

          subject{ -> {
            put "/api/v1/load/groups/allocate_user", json_data}
          }

          it { should change(Allocation,:count).by(1) }
          it { should change(User,:count).by(0) }

          it {
            expect{
              put "/api/v1/load/groups/allocate_user", json_data

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }
          }
        end

        context 'and existing user and non existing UC' do
          let!(:json_data){ # user: aluno3, profile: tutor a distância
            { allocation: { cpf: "47382348113", perfil: 18, periodo: "1", ano: "2011", codTurma: "QM-CAU", codDisciplina: "UC01", codGraduacao: "109"} }
          }

          subject{ -> {
            put "/api/v1/load/groups/allocate_user", json_data}
          }

          it { should change(Allocation,:count).by(0) }
          it { should change(User,:count).by(0) }

          it {
            expect{
              put "/api/v1/load/groups/allocate_user", json_data

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }
          }
        end

        context 'and existing user and non existing course' do
          let!(:json_data){ # user: aluno3, profile: tutor a distância
            { allocation: { cpf: "47382348113", perfil: 18, periodo: "1", ano: "2011", codTurma: "QM-CAU", codDisciplina: "RM301", codGraduacao: "C01"} }
          }

          subject{ -> {
            put "/api/v1/load/groups/allocate_user", json_data}
          }

          it { should change(Allocation,:count).by(0) }
          it { should change(User,:count).by(0) }

          it {
            expect{
              put "/api/v1/load/groups/allocate_user", json_data

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }
          }
        end

        context 'and existing user and non existing group' do
          let!(:json_data){ # user: aluno3, profile: tutor a distância
            { allocation: { cpf: "47382348113", perfil: 18, periodo: "1", ano: "2011", codTurma: "T01", codDisciplina: "RM301", codGraduacao: "109"} }
          }

          subject{ -> {
            put "/api/v1/load/groups/allocate_user", json_data}
          }

          it { should change(Allocation,:count).by(0) }
          it { should change(User,:count).by(0) }

          it {
            expect{
              put "/api/v1/load/groups/allocate_user", json_data

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }
          }
        end

        context 'and existing user and existing course without offer and group' do
          let!(:json_data){ # user: aluno3, profile: tutor a distância
            { allocation: { cpf: "47382348113", perfil: 18, codGraduacao: "109"} }
          }

          subject{ -> {
            put "/api/v1/load/groups/allocate_user", json_data}
          }

          it { should change(Course.find_by_code("109").allocations,:count).by(1) }
          it { should change(User,:count).by(0) }

          it {
            expect{
              put "/api/v1/load/groups/allocate_user", json_data

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }
          }
        end

        context 'and non existing user' do # futuramente este teste deverá criar um novo usuário a partir do MA (cpf deverá ser válido para usuário no MA)
          let!(:json_data){
            { allocation: { cpf: "cpf", perfil: 18, periodo: "1", ano: "2011", codTurma: "QM-CAU", codDisciplina: "RM301", codGraduacao: "109"} }
          }

          subject{ -> {
            put "/api/v1/load/groups/allocate_user", json_data}
          }

          it { should change(Allocation,:count).by(0) }
          it { should change(User,:count).by(0) }

          it {
            expect{
              put "/api/v1/load/groups/allocate_user", json_data

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }
          }
        end

        context 'and existing user and missing param' do
          let!(:json_data){ # user: aluno3, profile: tutor a distância
            { allocation: { cpf: "47382348113", perfil: 18, ano: "2011", codTurma: "QM-CAU", codDisciplina: "RM301", codGraduacao: "109"} }
          }

          subject{ -> {
            put "/api/v1/load/groups/allocate_user", json_data}
          }

          it { should change(Allocation,:count).by(0) }
          it { should change(User,:count).by(0) }

          it {
            expect{
              put "/api/v1/load/groups/allocate_user", json_data
              response.status.should eq(404)
            }
          }
        end

      end

      context "with invalid ip" do
        it "gets a not authorized" do
          json_data = { allocation: { cpf: "47382348113", perfil: 18, periodo: "1", ano: "2011", codigo: "QM-CAU", codDisciplina: "RM301", codGraduacao: "109"} }
          put "/api/v1/load/groups/allocate_user", json_data, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(401)
        end
      end
    end #allocate_user

  end #groups

  describe ".user" do

    describe "post" do

      context "with valid ip" do

        context 'non existing user at Solar must get data from MA' do
          cpf = ENV['VALID_CPF']
          let!(:json_data){ { cpf: cpf } }

          it {
            expect{
              post "/api/v1/load/user/", json_data

              User.where(cpf: cpf).count.should eq(1)

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(1) # 1 basic
          }
        end

        context 'existing user at Solar' do

          it "must synchronize with MA" do
            cpf = ENV['VALID_CPF']
            post "/api/v1/load/user/", {cpf: cpf}

            user = User.find_by_cpf(cpf)
            user.email.should eq(ENV['VALID_EMAIL'])

            response.status.should eq(201)
            response.body.should == {ok: :ok}.to_json
          end
        end

        context 'existing user at Solar with same email' do

          it "must do nothing" do
            cpf = ENV['VALID_CPF']
            post "/api/v1/load/user/", {cpf: cpf}

            User.where(cpf: cpf).count.should eq(1) # user

            response.status.should eq(201)
            response.body.should == {ok: :ok}.to_json
          end
        end

        context 'non existing user at MA' do

          it "must get an error" do
            post "/api/v1/load/user/", {cpf: "43463518678"}

            response.status.should eq(404)
          end
        end
      end

      context "with invalid ip" do
        it "gets a not authorized" do
          post "/api/v1/load/user/", {cpf: ENV['VALID_CPF']}, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(401)
        end
      end

    end #post


  end #user

end