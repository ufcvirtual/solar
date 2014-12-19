require "spec_helper"

describe "Scores" do

  fixtures :all
  include ActionDispatch::TestProcess

  let!(:user) { User.find_by_username("aluno1") }
  let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
  let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

  # {
  #   assignments: [
  #     {
  #       name: name,
  #       enunciation: akak,
  #       type_assignment: 0/1, #[individual/group]
  #       situation: [not_started corrected sent without_group to_be_sent not_sent]
  #       comments: ['a', 'a']
  #       grade: nota,
  #       start_date: '',
  #       end_date: ''
  #     }
  #   ],
  #   discussions: [
  #     {
  #       name: name,
  #       count_posts: count
  #     }
  #   ],
  #   history_access: [
  #     {
  #       date: date,
  #       time: time
  #     }
  #   ]
  # }

  # {
  #   situation: s,
  #   grade: info[:grade],
  #   has_comments: (not(info[:comments].nil?) and info[:comments].any?),
  #   has_files: info[:has_files],
  #   group_id: group_id,
  #   file_sent_date: info[:file_sent_date]
  # }

  context "with valid access token" do
    it 'gets the list of score informations' do
      get "/api/v1/groups/1/scores/info", access_token: token.token

      response.status.should eq(200)
      response.body.should == {}.to_json
    end
  end # context with valid user

  context "without access token" do

    it 'dont get list of score informations' do
      get "/api/v1/groups/1/scores/info", access_token: token.token

      response.status.should eq(401)
      response.body.should == {error: "unauthorized"}.to_json
    end
  end

end
