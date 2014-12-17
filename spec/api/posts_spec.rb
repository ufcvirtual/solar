require "spec_helper"

describe "Posts" do

  fixtures :all
  include ActionDispatch::TestProcess

  let!(:user) { User.find_by_username("aluno1") }
  let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
  let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

  describe ".new" do
    context "with permission" do
      it "create a post" do
        post "/api/v1/discussions/2/posts", group_id: 3, discussion_post: {content: "content"}, access_token: token.token

        response.status.should eq(201)
        response.body.should == {id: Post.first.id}.to_json
      end
    end

    context "without permission" do
      it "try to create a post" do
        token_withou_permission = Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: User.find_by_username("admin").id
        post "/api/v1/discussions/2/posts", group_id: 3, discussion_post: {content: "content"}, access_token: token_withou_permission.token

        response.status.should eq(404)
        response.body.should == {}.to_json
      end
    end
  end

  describe ".files" do

    context "with access token" do

      it "add files to post" do
        file = fixture_file_upload('/files/file_10k.dat')
        post "/api/v1/posts/13/files", group_id: 3, file: file, access_token: token.token

        response.status.should eq(201)
        response.body.should eq({ids: [PostFile.last.id]}.to_json)
      end

      it "gets post files list" do
        get "/api/v1/posts/13/files", group_id: 3, access_token: token.token
        response.status.should eq(200)

        file = Post.find(13).files.first
        response.body.should == [{
            id: file.id,
            name: file.attachment_file_name,
            content_type: file.attachment_content_type,
            updated_at: file.attachment_updated_at,
            size: file.attachment_file_size,
            url: "http://localhost:3000/posts/#{file.post.id}/post_files/#{file.id}/api_download"
          }].to_json
      end

    end #context with access token

    context "without access token" do

      it 'gets an unauthorized error' do
        get "/api/v1/posts/13/files", group_id: 3

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end #context without access token

  end #describle .files

  describe ".list" do

    context "with valid access token" do

      it "lists new posts" do
        get "/api/v1/discussions/2/posts/new", group_id: 3, access_token: token.token
        response.status.should eq(200)

        expect(json).to have_key('newer')
        expect(json['newer']).to eq(0)

        expect(json).to have_key('older')
        expect(json['older']).to eq(0)

        expect(json).to have_key('posts')
        expect(json['posts'].count).to eq(3)
      end

      it "lists new posts by date" do
        # recuperar o datetime do último post feito (ou seja, o mais recente) -1 minuto
        # deste modo, apenas ele será retornado como mais novos que a data passada
        newest_post_date = "#{(Discussion.find(2).posts.first.updated_at.to_datetime - 1.minute)}"
        get "/api/v1/discussions/2/posts/new", group_id: 3, date: newest_post_date, access_token: token.token
        response.status.should eq(200)

        expect(json).to have_key('newer')
        expect(json['newer']).to eq(0)

        expect(json).to have_key('older')
        expect(json['older']).to eq(2)

        expect(json).to have_key('posts')
        expect(json['posts'].count).to eq(1)
      end

      it "lists an empty array" do
        get "/api/v1/discussions/3/posts/new", group_id: 1, access_token: token.token
        response.status.should eq(200)

        expect(json).to have_key('newer')
        expect(json['newer']).to eq(0)

        expect(json).to have_key('older')
        expect(json['older']).to eq(0)

        expect(json).to have_key('posts')
        expect(json['posts'].count).to eq(0)
      end

      it "lists posts history with old date" do
        get "/api/v1/discussions/2/posts/history", group_id: 3, date: "20100204T1416", access_token: token.token
        response.status.should eq(200)

        expect(json).to have_key('newer')
        expect(json['newer']).to eq(3)

        expect(json).to have_key('older')
        expect(json['older']).to eq(0)

        expect(json).to have_key('posts')
        expect(json['posts'].count).to eq(0)
      end

      it "lists posts history with new date" do
        get "/api/v1/discussions/2/posts/history", group_id: 3, date: DateTime.now, access_token: token.token
        response.status.should eq(200)

        expect(json).to have_key('newer')
        expect(json['newer']).to eq(0)

        expect(json).to have_key('older')
        expect(json['older']).to eq(0)

        expect(json).to have_key('posts')
        expect(json['posts'].count).to eq(3)
      end

      it "don't list posts history without date" do
        get "/api/v1/discussions/2/posts/history", group_id: 3, access_token: token.token
        response.status.should eq(400)
        response.body.should == "[{:params=>[\"date\"], :messages=>[\"is missing\"]}]"
      end
    end #context with access token

    context "without access token" do

      it 'gets an unauthorized error' do
        get "/api/v1/discussions/2/posts/history", group_id: 3, date: DateTime.now

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end

      it 'gets an unauthorized error' do
        get "/api/v1/discussions/2/posts/new", group_id: 3, date: DateTime.now

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end

      it 'gets an unauthorized error' do
        get "/api/v1/discussions/2/posts/new", group_id: 3

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end #context without access token

    context "without access to discussion" do

      it 'gets a permission  error' do
        get "/api/v1/discussions/4/posts/history", group_id: 6, date: DateTime.now, access_token: token.token

        response.status.should eq(404)
        response.body.should == {}.to_json
      end

      it 'gets a permission error' do
        get "/api/v1/discussions/4/posts/new", group_id: 6, date: DateTime.now, access_token: token.token

        response.status.should eq(404)
        response.body.should == {}.to_json
      end

      it 'gets a permission error' do
        get "/api/v1/discussions/4/posts/new", group_id: 6, access_token: token.token

        response.status.should eq(404)
        response.body.should == {}.to_json
      end
    end

  end #describle .list

end
