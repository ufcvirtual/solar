require "spec_helper"

describe "Discussions" do

  fixtures :all

  describe ".list" do

    context "with access token" do

      let!(:user) { User.find_by_username("aluno1") }
      let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

      it "gets list of UC" do
        get "/api/v1/groups/2/discussions", access_token: token.token

        response.status.should eq(200)
        response.body.should == [
          {
            id: 9,
            status: "0",
            name: "Forum 7",
            description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nisi.",
            last_post_date: nil,
            start_date: (Date.today >> 1).to_time,
            end_date: (Date.today >> 5).to_time
          }
        ].to_json
      end

    end

    context "without access token" do

      it 'gets an unauthorized error' do
        get "/api/v1/groups/2/discussions"

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end

  end
end
