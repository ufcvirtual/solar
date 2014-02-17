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

  end

  describe ".load" do

    context "with valid ip" do # ip is included on list of ips with access

      context "and new semester" do
        let!(:xml_data){ {ano: "2014", periodo: "2", codDisciplina: "RM302", codigo: "T01", codGraduacao: "LQUIM", 
            dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
            }.to_xml(root: "turmas") }

        subject{ -> {
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'}
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
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'
          response.status.should eq(201) # created
        }
      end

      context "and dates smaller then today" do
        let!(:xml_data){ {ano: "2014", periodo: "2", codDisciplina: "RM302", codigo: "T01", codGraduacao: "LQUIM", 
            dtInicio: Date.current - 1.month, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
            }.to_xml(root: "turmas") }

        subject{ -> { 
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'} 
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
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'
          response.status.should eq(201) # created
        }
      end


      context "and existing semester" do
        let!(:xml_data){ xml_data = {ano: "2013", periodo: "1", codDisciplina: "RM404", codigo: "RM0121", codGraduacao: "RM404", 
          dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
          }.to_xml(root: "turmas") }

        subject{ -> { 
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'} 
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
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'
          response.status.should eq(201) # created
        }
      end

      context "and existing offer" do
        let!(:xml_data){ xml_data = {ano: "2013", periodo: "1", codDisciplina: "RM414", codigo: "RM0121", codGraduacao: "RM404", 
          dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
          }.to_xml(root: "turmas") }

        subject{ -> { 
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'} 
        }

        it { should change(Semester,:count).by(0) }
        it { should change(Offer,:count).by(0) }
        it { should change(Group,:count).by(1) }
        it { should change(Allocation,:count).by(3) }

        it {
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'
          response.status.should eq(201) # created
        }
      end

      context "and existing group" do
        let!(:xml_data){ xml_data = {ano: "2011", periodo: "1", codDisciplina: "RM301", codigo: "QM-MAR", codGraduacao: "LQUIM", 
          dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
          }.to_xml(root: "turmas") }

        subject{ -> { 
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'} 
        }

        it { should change(Semester,:count).by(0) }
        it { should change(Offer,:count).by(0) }
        it { should change(Group,:count).by(0) }
        it { should change(Allocation,:count).by(3) }

        it {
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'
          response.status.should eq(201) # created
        }
      end

      context "and non existing uc" do
        let!(:xml_data){ xml_data = {ano: "2011", periodo: "1", codDisciplina: "UC01", codigo: "QM-MAR", codGraduacao: "LQUIM", 
          dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
          }.to_xml(root: "turmas") }

        subject{ -> { 
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'} 
        }

        it { should change(Semester,:count).by(0) }
        it { should change(Offer,:count).by(0) }
        it { should change(Group,:count).by(0) }
        it { should change(Allocation,:count).by(0) }

        it {
          post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml'
          response.status.should eq(404)
        }
      end

    end

    context "with invalid ip" do # ip isn't included on list of ips with access
      it 'gets an unauthorized error' do
        xml_data = {ano: "2013", periodo: "1", codDisciplina: "RM404", codigo: "RM0121", codGraduacao: "RM404", 
          dtInicio: Date.current + 1.day, dtFim: Date.current + 6.months, professores: ["21569104646", "21872285848", "31877336203"]
          }.to_xml(root: "turmas")
        post "/api/v1/load/groups", xml_data, "CONTENT_TYPE"=> 'application/xml', "REMOTE_ADDR" => "127.0.0.2"
        response.status.should eq(404)
      end
    end

  end

end
