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
    context "editors" do

      it "from modulo academico" do
        editors = {
          cod_curriculum_unit: "RM404",
          editors: User.where(username: %w(user3 user4)).map(&:cpf)
        }.to_xml(root: :load_editors)

        expect{
          post "/api/v1/curriculum_units/load/editors", editors, "CONTENT_TYPE" => "application/xml"

          response.status.should eq(201)
          response.body.should == {ok: :ok}.to_xml
        }.to change{Allocation.count}.by(2)
      end

    end
  end

end
