require "spec_helper"

describe "Posts" do

  fixtures :all

  describe ".files" do

    include ActionDispatch::TestProcess

    context "with access token" do

      let!(:user) { User.find_by_username("aluno1") }
      let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

      it "create a post" do
        post "/api/v1/discussions/2/posts", access_token: token.token, post:{content:"Qualquer"}

        response.status.should eq(201)
        response.body.should == {id: Post.first.id}.to_json
      end

      it "add files to post" do
        file = fixture_file_upload('/files/file_10k.dat')
        post "/api/v1/posts/7/files", file: file, access_token: token.token

        response.status.should eq(201) 

        response.body.should eq({ids: [PostFile.last.id]}.to_json)
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
