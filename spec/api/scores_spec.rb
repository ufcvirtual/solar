require "spec_helper"

describe "Scores" do

  fixtures :all
  include ActionDispatch::TestProcess

  let!(:user) { User.find_by_username("aluno1") }
  let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
  let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

  context "with valid access token" do
    it 'gets the list of score informations' do
      get "/api/v1/groups/2/scores/info", access_token: token.token

      response.status.should eq(200)

      body = JSON.parse(response.body)

      body["assignments"].first.keys.should == %w[id type_assignment name enunciation situation grade start_date end_date comments]
      body["assignments"].last["comments"].first.keys.should == %w[user_id user_name comment created_at]
      body["discussions"].first.keys.should == %w[id name posts_count]
    end
  end # context with valid user

  context "without access token" do

    it 'dont get list of score informations' do
      get "/api/v1/groups/1/scores/info", access_token: nil

      response.status.should eq(401)
      response.body.should == {error: "unauthorized"}.to_json
    end

    it 'dont get list of score informations for unauthorized group' do
      get "/api/v1/groups/4/scores/info", access_token: token.token

      response.status.should eq(401)
    end
  end

end
