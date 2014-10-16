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
        response.body.should == { id: user.id, name: user.name, username: user.username, email: user.email, photo: "/api/v1/users/#{user.id}/photo" }.to_json
      end
    end

    context "without access token" do

      it 'gets an unauthorized error' do
        get "/api/v1/users/me"

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end

  end # me

  describe ".user" do

    describe "/" do

      context "with valid ip" do
        context "and valid data" do
          it {
            user = { name: "Usuario novo", nick: "usuario novo", cpf: "69278278203", birthdate: "1980-10-17", gender: true, email: "email@email.com" }

            expect{
              post "/api/v1/user/", user

              response.status.should eq(201)
              response.body.should == {id: User.find_by_cpf("69278278203").id}.to_json
            }.to change{User.where(cpf: "69278278203").count}.by(1)
          }
        end

        context "and invalid data" do
          it {
            user = { name: "Usuario novo", nick: "usuario novo", cpf: "69278278203", birthdate: "1980-10-17", gender: true } # missing email

            expect{
              post "/api/v1/user/", user

              response.status.should eq(400)
            }.to change{User.where(cpf: "69278278203").count}.by(0)
          }
        end
      end

      context "with invalid ip" do
        it "gets a not found error" do
          user = { name: "Usuario novo", nick: "usuario novo", cpf: "69278278203", birthdate: "1980-10-17", gender: true, email: "email@email.com" }

          expect{
            post "/api/v1/user/", user, "REMOTE_ADDR" => "127.0.0.2"
            response.status.should eq(404)
          }.to change{User.where(cpf: "69278278203").count}.by(0)
        end
      end

    end

  end # .user

end
