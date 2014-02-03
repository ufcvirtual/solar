require "spec_helper"

describe "Posts" do

  fixtures :all

  describe ".files" do

    include ActionDispatch::TestProcess

    context "with access token" do

      let!(:user) { User.find_by_username("aluno1") }
      let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

      it "create a post to add files" do
        # criar um post aqui
      end

      it "create a post and set a file to it" do

        # post "/api/v1/posts", access_token: token.token, 
        # response.status.should eq(201)
        # post_id = response.body

        # raise "#{@post.as_json} -- #{Post.first.as_json}"
        # file = fixture_file_upload('/files/file_10k.dat')
        # post "/api/v1/posts/#{@post.id}/files", file: file, access_token: token.token

      end

      it "gets post files list" do
        get "/api/v1/posts/7/files", access_token: token.token
        response.status.should eq(200)

        file = Post.find(7).files.first
        response.body.should == [{
            id: file.id,
            name: file.attachment_file_name,
            content_type: file.attachment_content_type,
            updated_at: file.attachment_updated_at,
            size: file.attachment_file_size,
            url: "http://localhost:3000/posts/#{file.post.id}/post_files/#{file.id}/download"
          }].to_json
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
