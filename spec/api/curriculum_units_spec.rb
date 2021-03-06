require "spec_helper"

describe "CurriculumUnits" do

  fixtures :all

  describe ".list" do

    context "with access token" do

      let!(:user) { User.find_by_username("aluno1") }
      let!(:token) { Doorkeeper::AccessToken.create! resource_owner_id: user.id }

      it "gets list of UC" do
        get "/api/v1/curriculum_units", access_token: token.token

        response.status.should eq(200)
        response.body.should == [{id: 1,code: "RM404",name: "Introducao a Linguistica"},{id: 3,code: "RM301",name: "Quimica I"},{id: 2,code: "RM405",name: "Teoria da Literatura I"}].to_json
      end

      it "gets list of UC with groups" do
        get "/api/v1/curriculum_units/groups", access_token: token.token

        response.status.should eq(200)
        response.body.should == [
          {id: 1, code: "RM404", name: "Introducao a Linguistica",
            groups: [{id: 1, code: "IL-FOR", semester: "2011.1"}]},
          {id: 3, code: "RM301", name: "Quimica I",
            groups: [{id: 3, code: "QM-CAU", semester: "2011.1"}]},
          {id: 2, code: "RM405", name: "Teoria da Literatura I",
            groups: [{id: 2, code: "TL-CAU", semester: "2011.1"}]}].to_json
      end
    end

    context "without access token" do

      it 'gets an unauthorized error to list' do
        get "/api/v1/curriculum_units"

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end

      it 'gets an unauthorized error to list with groups' do
        get "/api/v1/curriculum_units/groups"

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end

  end # list

  describe ".curriculum_unit" do

    describe "post" do

      context "with valid ip" do

        context 'create curriculum_unit' do
          let!(:json_data){ { 
            name: "UC 01",
            code: "UC01",
            curriculum_unit_type_id: 1
          } }

          subject{ -> { post "/api/v1/curriculum_unit", json_data } } 

          it { should change(CurriculumUnit,:count).by(1) }

          it {
            post "/api/v1/curriculum_unit", json_data
            response.status.should eq(201)
            response.body.should == {id: CurriculumUnit.find_by_code("UC01").id, course_id: nil}.to_json
          }
        end

        context 'update if exists' do
          let!(:json_data){ { 
            name: "UC01",
            code: "RM404",
            curriculum_unit_type_id: 1,
            update_if_exists: true
          } }

          subject{ -> { post "/api/v1/curriculum_unit", json_data } } 

          it { should change(CurriculumUnit,:count).by(0) }
          it { should change(CurriculumUnit.where(resume: "UC01"),:count).by(0) }
          it { should change(CurriculumUnit.where(resume: "Pensando mais a longo prazo, a percepo das dificuldades nao causa impacto indireto na reavaliacao da formula da ressonancia racionalista."),:count).by(0) }
          it { should change(CurriculumUnit.where(name: "UC01"),:count).by(1) }
          it { should change(CurriculumUnit.where(name: "Introducao a Linguistica"),:count).by(-1) }

          it {
            post "/api/v1/curriculum_unit", json_data
            response.status.should eq(201)
            response.body.should == {id: CurriculumUnit.find_by_code("RM404").id, course_id: nil}.to_json
          }
        end

        context 'create curriculum_unit tipo livre' do
          let!(:json_data){ { 
            name: "UC 01",
            code: "UC01",
            curriculum_unit_type_id: 3
          } }

          subject{ -> { post "/api/v1/curriculum_unit", json_data } } 

          it { should change(Course,:count).by(1) }
          it { should change(CurriculumUnit,:count).by(1) }

          it {
            post "/api/v1/curriculum_unit", json_data
            response.status.should eq(201)
            response.body.should == {id: CurriculumUnit.find_by_code("UC01").id, course_id: Course.find_by_code("UC01").id}.to_json
          }
        end

      end

    end # post

    describe "put" do

      context "with valid ip" do

        context 'update curriculum_unit' do
          let!(:json_data){ { code: "UC01" } }

          subject{ -> { put "/api/v1/curriculum_unit/2", json_data } } 

          it { should change(CurriculumUnit.where(code: "RM405"),:count).by(-1) }
          it { should change(CurriculumUnit.where(code: "UC01"),:count).by(1) }

          it {
            put "/api/v1/curriculum_unit/2", json_data
            response.status.should eq(200)
            response.body.should == {ok: :ok}.to_json
          }
        end

        context 'dont update curriculum_unit - existing code' do
          let!(:json_data){ { code: "RM404" } }

          subject{ -> { put "/api/v1/curriculum_unit/2", json_data } } 

          it { should change(CurriculumUnit.where(code: "RM405"),:count).by(0) }

          it {
            put "/api/v1/curriculum_unit/2", json_data
            response.status.should eq(422)
          }
        end

        context 'dont update curriculum_unit - missing params' do
          subject{ -> { put "/api/v1/curriculum_unit/2" } } 

          it { should change(CurriculumUnit.where(code: "RM405"),:count).by(0) }

          it {
            put "/api/v1/curriculum_unit/2"
            response.status.should eq(400)
          }
        end

      end

    end # put

  end # .curriculum_unit

  describe "disciplines" do
    it "list all by semester" do
      get "/api/v1/disciplines", {semester: "2012.1"}

      response.status.should eq(200)
      response.body.should == [{id: 3, code: "RM301", name: "Quimica I"}, {id: 1, code: "RM404", name: "Introducao a Linguistica" }].to_json
    end

    it "list all by semester and type" do
      get "/api/v1/disciplines", {semester: "2012.1", course_type_id: 2}

      response.status.should eq(200)
      response.body.should == [{id: 3, code: "RM301", name: "Quimica I"}].to_json
    end

    it "list all by semester and course" do
      get "/api/v1/disciplines", {semester: "2012.1", course_id: 2}

      response.status.should eq(200)
      response.body.should == [{id: 3, code: "RM301", name: "Quimica I"}].to_json
    end

    it "list all by semester, type and course" do
      get "/api/v1/disciplines", {semester: "2013.1", course_type_id: 5, course_id: 3}

      response.status.should eq(200)
      response.body.should == [{id: 5, code: "RM414", name: "Literatura Brasileira I"}].to_json
    end
  end # describe disciplines

end
