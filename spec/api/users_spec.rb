require "spec_helper"

describe "Users" do

  fixtures :all

  describe ".me" do

    context "with access token" do

      let!(:user) { User.find_by_username("aluno1") }
      let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

      it "gets current user info" do
        get "/api/v1/users/me", access_token: token.token

        response.status.should eq(200)
        response.body.should == { id: user.id, name: user.name, username: user.username, email: user.email, photo: "http://localhost:3000/users/#{user.id}/photo" }.to_json
      end
    end

    context "without access token" do

      it 'gets an unauthorized error' do
        get "/api/v1/users/me"

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end

  end
end
