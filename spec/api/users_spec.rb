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
        it "gets a not authorized" do
          user = { name: "Usuario novo", nick: "usuario novo", cpf: "69278278203", birthdate: "1980-10-17", gender: true, email: "email@email.com" }

          expect{
            post "/api/v1/user/", user, "REMOTE_ADDR" => "127.0.0.2"
            response.status.should eq(401)
          }.to change{User.where(cpf: "69278278203").count}.by(0)
        end
      end

    end

  end # .user

  describe "profiles" do

    context "get a list of all users" do

      it "with profile" do
        get "/api/v1/profiles/1/users"

        response.status.should eq(200)
        response.body.should == [{id: 7, name: "Aluno 1", cpf: "32305605153", email: "aluno1@solar.ufc.br"}, {id: 8, name: "Aluno 2", cpf: "98447432904", email: "aluno2@solar.ufc.br"}, {id: 9, name: "Aluno 3", cpf: "47382348113", email: "aluno3@aluno3.br"}, {id: 2, name: "User 2", cpf: "23885393905", email: "user2@email.com"}, {id: 3, name: "User 3", cpf: "11016853521", email: "user3@email.com"}, {id: 1, name: "Usuario do Sistema", cpf: "43463518678", email: "user@user.com"}].to_json
      end

      it "with profile at group" do
        get "/api/v1/profiles/1/users", {groups_id: [3]}

        response.status.should eq(200)
        response.body.should == [{id: 7, name: "Aluno 1", cpf: "32305605153", email: "aluno1@solar.ufc.br"}, {id: 8, name: "Aluno 2", cpf: "98447432904", email: "aluno2@solar.ufc.br"}, {id: 9, name: "Aluno 3", cpf: "47382348113", email: "aluno3@aluno3.br"}, {id: 1, name: "Usuario do Sistema", cpf: "43463518678", email: "user@user.com"}].to_json
      end

      it "with profile active or not" do
        get "/api/v1/profiles/1/users", {groups_id: [5], only_active: false}

        response.status.should eq(200)
        response.body.should == [{id: 9, name: "Aluno 3", cpf: "47382348113", email: "aluno3@aluno3.br"}, {id: 1, name: "Usuario do Sistema", cpf: "43463518678", email: "user@user.com"}].to_json
      end

      it "with profiles" do
        get "/api/v1/profiles/1,2/users"

        response.status.should eq(200)
        response.body.should == [{id: 7, name: "Aluno 1", cpf: "32305605153", email: "aluno1@solar.ufc.br"},
          {id: 8, name: "Aluno 2", cpf: "98447432904", email: "aluno2@solar.ufc.br"},
          {id: 9, name: "Aluno 3", cpf: "47382348113", email: "aluno3@aluno3.br"},
          {id: 6, name: "Professor", cpf: "21872285848", email: "prof@solar.ufc.br"},
          {id: 5, name: "Professor 2", cpf: "21569104646", email: "prof2@email.com"},
          {id: 2, name: "User 2", cpf: "23885393905", email: "user2@email.com"},
          {id: 3, name: "User 3", cpf: "11016853521", email: "user3@email.com"},
          {id: 1, name: "Usuario do Sistema", cpf: "43463518678", email: "user@user.com"}
        ].to_json
      end

      it "with profile and course" do
        get "/api/v1/profiles/5/users", {course_id: 2}

        response.status.should eq(200)
        response.body.should == [{id: 12, name: "Coordenador", cpf: "04982281505", email: "coorddisc@coorddisc.br"},
          {id: 14, name: "editor", cpf: "87789615211", email: "editor@com.br"},
          {id: 3, name: "User 3", cpf: "11016853521", email: "user3@email.com"}
        ].to_json
      end

      it "when params has non existing profile" do
        get "/api/v1/profiles/100/users"

        response.status.should eq(200)
      end

    end

    context "get an error" do

      context "try access with invalid ip" do
        it "at users by profile list" do
          get "/api/v1/profiles/1/users", {}, {"REMOTE_ADDR" => "127.0.0.2"}
          response.status.should eq(401)
        end
      end

      it "when params has non existing group" do
        get "/api/v1/profiles/1/users", groups_id: [100]
        response.status.should eq(404)
      end

    end

  end # describe profile

end
