require "spec_helper"

describe "Lessons" do

  fixtures :all
  include ActionDispatch::TestProcess

  let!(:user) { User.find_by_username("aluno1") }
  let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
  let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

  context "with valid access token" do
    it 'gets the list of lessons' do
      get "/api/v1/groups/2/lessons", access_token: token.token

      response.status.should eq(200)

      response.body.should == [{id: 3, name: "modulo 1 / turma 2", description: nil, order: nil, is_default: false, \
        lessons: [{id: 6, order: 6, status: 1, type: "LINK", name: "aula 6", url: "http://www.google.com", start_date: "2011-03-25", end_date: "2022-05-06"}, \
          {id: 10, order: 10, status: 1, type: "FILE", name: "aula com arquivos", url: "/api/v1/groups/2/lessons/10/index.html", start_date: "2011-03-25", end_date: "2022-05-06"}]}].to_json
    end

    it "gets lesson" do
      ## copy file to local
      lesson = Lesson.find(10)
      unless File.exist?(lesson.path(true))
        file = File.join(Rails.root, 'test', 'fixtures', 'files', 'lessons', 'index.html')
        to = File.join(Rails.root, 'media', 'lessons', '10')
        FileUtils.mkdir_p to
        FileUtils.cp_r file, to
      end

      get "/api/v1/groups/2/lessons/10/index.html", access_token: token.token
      response.status.should eq(200)
    end

  end # context with valid user

  context "without access token" do

    it 'dont get list of lessons' do
      get "/api/v1/groups/2/lessons", access_token: nil

      response.status.should eq(401)
      response.body.should == {error: "unauthorized"}.to_json
    end

    it "dont get lesson" do
      get "/api/v1/groups/2/lessons/10/index.html", access_token: nil
      response.status.should eq(401)
    end

  end

end
