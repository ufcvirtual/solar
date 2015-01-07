require "spec_helper"

describe "Agendas" do

  fixtures :all
  include ActionDispatch::TestProcess

  let!(:user) { User.find_by_username("aluno1") }
  let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
  let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

  context "with valid access token" do
    it 'gets agenda informations' do
      get "/api/v1/groups/1/agenda", access_token: token.token

      body = JSON.parse(response.body)
      body.first.keys.should == %w[type title start_date end_date all_day start_hour end_hour]
    end
  end # context with valid user

  context "without access token" do

    it 'dont get agenda informations' do
      get "/api/v1/groups/1/agenda", access_token: nil

      response.status.should eq(401)
      response.body.should == {error: "unauthorized"}.to_json
    end

    it 'dont get agenda informations for unauthorized group' do
      get "/api/v1/groups/4/agenda", access_token: token.token

      response.status.should eq(401)
    end
  end

end
