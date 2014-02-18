require 'test_helper'

class DiscussionsWithPostsTest < ActionDispatch::IntegrationTest
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 

  def setup
    @quimica_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 3)
  end

  def login(user)
    login_as user, scope: :user
  end

  ## API - Mobilis
  test "posts de forum criados a partir de uma data" do
    login users(:aluno1)

    get @quimica_tab
    get "/discussions/1/posts/news/20001010102410", format: :json

    correct_response = [
      {before: 0, after: 0},
      discussion_posts(:post_4_forum_1).to_mobilis,
      discussion_posts(:post_3_forum_1).to_mobilis,
      discussion_posts(:post_2_forum_1).to_mobilis,
      discussion_posts(:post_1_forum_1).to_mobilis
    ].to_json

    assert_equal JSON.parse(@response.body), JSON.parse(correct_response)
  end

end