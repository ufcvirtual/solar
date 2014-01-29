require "spec_helper"

describe "Users" do

  describe ".me" do

    context "with access token" do

      FactoryGirl.create(:profile)
      let!(:user) { FactoryGirl.create(:user) }
      let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

      it "gets current user info" do
        get "/api/v1/users/me", access_token: token.token

        response.status.should eq(200)
        response.body.should == { name: user.name, username: user.username, email: user.email, photo: "/users/#{user.id}/photo" }.to_json
      end
    end

    context "without access token" do

      it 'gets an error' do
        get "/api/v1/users/me"

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end

  end
end
