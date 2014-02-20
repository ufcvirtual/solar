require "spec_helper"

describe "CurriculumUnits" do

  fixtures :all

  describe ".list" do

    context "with access token" do

      let!(:user) { User.find_by_username("aluno1") }
      let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

      it "gets list of UC" do
        get "/api/v1/curriculum_units", access_token: token.token

        response.status.should eq(200)
        response.body.should == [ { id: 5, code: "RM414", name: "Literatura Brasileira I" } ].to_json
      end

      it "gets list of UC with groups" do
        get "/api/v1/curriculum_units/groups", access_token: token.token

        response.status.should eq(200)
        response.body.should == [ { id: 5, code: "RM414", name: "Literatura Brasileira I", groups: [ { id: 5, code: "LB-CAR", semester: "2011.1"} ] } ].to_json
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

  end

  describe ".load" do
    
    describe "editors" do

      context "with valid ip" do
        context "and existing users" do
          it {
            editors = {load_editors: {
              codDisciplina: "RM404",
              editors: User.where(username: %w(user3 user4)).map(&:cpf)
            }}

            expect{
              post "/api/v1/curriculum_units/load/editors", editors

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(2)
          }
        end

        context "and non existing users" do
          it {
            editors = {load_editors: {
              codDisciplina: "RM404",
              editors: User.where(username: %w(userDontExist user3)).map(&:cpf) #only one user exists
            }}
            
            expect{
              post "/api/v1/curriculum_units/load/editors", editors

              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }.to change{Allocation.count}.by(1)
          }
        end

        context "and non existing uc" do
          it {
            editors = {load_editors: {
              codDisciplina: "UC01",
              editors: User.where(username: %w(user3 user4)).map(&:cpf) #only one user exists
            }}
            
            expect{
              post "/api/v1/curriculum_units/load/editors", editors

              response.status.should eq(404)
            }.to change{Allocation.count}.by(0)
          }
        end
      end

      context "with invalid ip" do
         it "gets a not found error" do
          editors = {load_editors: {
            codDisciplina: "RM404",
            editors: User.where(username: %w(user3 user4)).map(&:cpf)
          }}
          post "/api/v1/load/enrollments", editors, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(404)
        end
      end

    end # editors

  end # .load

end
