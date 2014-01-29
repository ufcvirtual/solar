require "spec_helper"

describe "Users" do

  describe ".me" do

    context "with access token" do
      let(:profile) { FactoryGirl.find(:profile) }
      let!(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "http://app.com") }
      let!(:user) { FactoryGirl.find(:user) }
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

      it "gets current user info" do
        get "/api/v1/users/me", access_token: token.token

        # expect(response.status).to equal(200)
        # expect(response.body).to equal({ name: user.name, username: user.username, email: user.email }.to_json)
        response.status.should eq(200)
        response.body.should == { name: user.name, username: user.username, email: user.email, photo: "/users/#{user.id}/photo" }.to_json
      end
    end

    context "without access token" do

      it 'gets an error' do
        get "/api/v1/users/me"

        # expect(response.status).to equal(401)
        # expect(response.body).to equal({error: "unauthorized"}.to_json)
        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end

  end
end
