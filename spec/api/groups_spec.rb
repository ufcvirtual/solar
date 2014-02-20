require "spec_helper"

describe "Groups" do

  fixtures :all

  describe ".list" do

    context "with access token" do

      let!(:user) { User.find_by_username("aluno1") }
      let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

      it "gets list of groups by UC" do
        get "/api/v1/curriculum_units/5/groups", access_token: token.token

        response.status.should eq(200)
        response.body.should == [ { id: 5, code: "LB-CAR", semester: "2011.1" } ].to_json
      end
    end

    context "without access token" do

      it 'gets an unauthorized error' do
        get "/api/v1/curriculum_units/5/groups"

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end

  end # .list

  describe ".load" do

    describe "groups" do

      context "with valid ip" do # ip is included on list of ips with access

        context "and new semester" do
          let!(:json_data){ {turmas: {ano: "2014", periodo: "2", codDisciplina: "RM302", codigo: "T01", codGraduacao: "LQUIM", 
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

        context "and dates smaller then today" do
          let!(:json_data){ {turmas: {ano: "2014", periodo: "2", codDisciplina: "RM302", codigo: "T01", codGraduacao: "LQUIM", 
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
          let!(:json_data){ {turmas: {ano: "2013", periodo: "1", codDisciplina: "RM404", codigo: "RM0121", codGraduacao: "RM404", 
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
          let!(:json_data){ {turmas: {ano: "2013", periodo: "1", codDisciplina: "RM414", codigo: "RM0121", codGraduacao: "RM404", 
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
          let!(:json_data){ {turmas: {ano: "2011", periodo: "1", codDisciplina: "RM301", codigo: "QM-MAR", codGraduacao: "LQUIM", 
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

        context "and non existing uc" do
          let!(:json_data){ {turmas: {ano: "2011", periodo: "1", codDisciplina: "UC01", codigo: "QM-MAR", codGraduacao: "LQUIM", 
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
        it "gets a not found error" do
          json_data = {turmas: {ano: "2013", periodo: "1", codDisciplina: "RM404", codigo: "RM0121", codGraduacao: "RM404", 
            dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
            }}
          post "/api/v1/load/groups", json_data, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(404)
        end
      end

    end # groups

    describe "enrollments" do

      context "with valid ip" do

        context 'and list of existing groups' do 
          let!(:json_data){
            { matriculas: {cpf: "11016853521", turmas: [ # user3
              {periodo: "1", ano: "2011", codigo: "QM-CAU", codDisciplina: "RM301", codGraduacao: "LQUIM"},
              {periodo: "1", ano: "2011", codigo: "QM-MAR", codDisciplina: "RM301", codGraduacao: "LQUIM"},
              {periodo: "1", ano: "2011", codigo: "TL-FOR", codDisciplina: "RM301", codGraduacao: "LQUIM"},
              {periodo: "1", ano: "2011", codigo: "TL-FOR", codDisciplina: "RM301", codGraduacao: "LQUIM"} # repetido propositalmente
            ]}}
          }

          it {
            expect{
              post "/api/v1/load/enrollments", json_data

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(3)
          }
        end

        context 'and list of non existing groups' do 
          let!(:json_data){
            { matriculas: {cpf: "11016853521", turmas: [ # user3
              {periodo: "1", ano: "2011", codigo: "T01", codDisciplina: "RM301", codGraduacao: "LQUIM"}, # turma não existe
              {periodo: "1", ano: "2011", codigo: "T02", codDisciplina: "RM301", codGraduacao: "LQUIM"}, # turma não existe
              {periodo: "1", ano: "2011", codigo: "TL-FOR", codDisciplina: "RM301", codGraduacao: "LQUIM"} # turma existe
            ]}}
          }

          it {
            expect{
              post "/api/v1/load/enrollments", json_data

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(1)
          }
        end

        context 'and non existing uc or course' do 
          let!(:json_data){
            { matriculas: {cpf: "11016853521", turmas: [ # user3
              {periodo: "1", ano: "2011", codigo: "QM-CAU", codDisciplina: "RM301", codGraduacao: "C01"}, # uc não existe
              {periodo: "1", ano: "2011", codigo: "QM-MAR", codDisciplina: "UC01", codGraduacao: "LQUIM"}, # curso não existe
              {periodo: "1", ano: "2011", codigo: "TL-FOR", codDisciplina: "RM301", codGraduacao: "LQUIM"} # turma existe
            ]}}
          }

          it {
            expect{
              post "/api/v1/load/enrollments", json_data

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(1)
          }
        end

        context 'and non existing user' do 
          let!(:json_data){
            { matriculas: {cpf: "cpf", turmas: [ # cpf inválido / usuário não encontrado
              {periodo: "1", ano: "2011", codigo: "QM-CAU", codDisciplina: "RM301", codGraduacao: "LQUIM"},
              {periodo: "1", ano: "2011", codigo: "QM-MAR", codDisciplina: "RM301", codGraduacao: "LQUIM"},
              {periodo: "1", ano: "2011", codigo: "TL-FOR", codDisciplina: "RM301", codGraduacao: "LQUIM"}
            ]}}
          }

          it {
            expect{
              post "/api/v1/load/enrollments", json_data

              response.status.should eq(404)
            }.to change{Allocation.count}.by(0)
          }
        end

      end

      context "with invalid ip" do
        it "gets a not found error" do
          json_data = { matriculas: {cpf: "11016853521", turmas: [ # user3
                        {periodo: "1", ano: "2011", codigo: "QM-CAU", codDisciplina: "RM301", codGraduacao: "LQUIM"}
                     ]}}
          post "/api/v1/load/enrollments", json_data, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(404)
        end
      end

    end # enrollments

  end # .load

end
