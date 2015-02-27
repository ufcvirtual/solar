require "spec_helper"

describe "Support Material Files" do

  fixtures :all
  include ActionDispatch::TestProcess

  let!(:user) { User.find_by_username("aluno1") }
  let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
  let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

  context "with valid access token" do
    it 'gets the list of files' do
      get "/api/v1/groups/1/support_material_files", access_token: token.token

      response.status.should eq(200)
      response.body.should == [{folder_name: "AULAS", files: [{ id: 3, type: "FILE", name: "index.html", url: "/api/v1/groups/1/support_material_files/3/download"}]}].to_json
    end

    it "gets file" do
      ## copy file to local
      file = SupportMaterialFile.find(3)
      unless File.exist?(file.attachment.path)
        file = File.join(Rails.root, 'test', 'fixtures', 'files', 'support_material_files', 'index.html')
        to = File.join(Rails.root, 'media', 'support_material_files')
        FileUtils.mkdir_p to
        FileUtils.cp_r file, to
        FileUtils.mv File.join(to, 'index.html'), File.join(to, '3_index.html')
      end

      get "/api/v1/groups/1/support_material_files/3/download", access_token: token.token
      response.status.should eq(200)
    end

  end # context with valid user

  context "without access token" do

    it 'dont get list of files' do
      get "/api/v1/groups/1/support_material_files", access_token: nil

      response.status.should eq(401)
      response.body.should == {error: "unauthorized"}.to_json
    end

    it "dont get file" do
      get "/api/v1/groups/1/support_material_files/3/download", access_token: nil
      response.status.should eq(401)
    end

  end

end
