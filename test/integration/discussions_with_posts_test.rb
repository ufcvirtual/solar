require 'test_helper'

class DiscussionsWithPostsTest < ActionDispatch::IntegrationTest
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 

  def setup
    @qm_cau_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 3)  # turma qm cau
    @qm_mar_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 11) # turma qm mar
    login users(:aluno1)
  end

  ## API - Mobilis - antigo / pode quebrar
  test "posts de forum criados a partir de uma data" do
    get @qm_cau_tab
    get "/discussions/1/posts/news/20001010102410", format: :json

    correct_response = [
      {before: 0, after: 0},
      discussion_posts(:post_4_ac_1).to_mobilis,
      discussion_posts(:post_3_ac_1).to_mobilis,
      discussion_posts(:post_2_ac_1).to_mobilis,
      discussion_posts(:post_1_ac_1).to_mobilis
    ].to_json

    assert_equal JSON.parse(@response.body), JSON.parse(correct_response)
  end

  ## API - Mobilis
  test "criar novo post no forum da turma QM CAU de quimica" do
    discussion_id = 1

    get @qm_cau_tab
    assert_difference('Post.count') do
      post "/discussions/1/posts", discussion_post: {content: "postagem de teste"}
    end

    assert_redirected_to discussion_posts_path(discussion_id)
  end

  ## API - Mobilis
  test "deletar post do forum da turma QM CAU de quimica" do
    discussion_id = 1

    get @qm_cau_tab
    post "/discussions/1/posts", discussion_post: {content: "postagem de teste"}
    @post = assigns(:post)

    assert_difference('Post.count', -1) do
      delete "/discussions/1/posts/#{@post.id}"
    end

    assert_response :success
  end

  ## API - Mobilis
  test "lista posts novos do forum da turma QM CAU de quimica" do
    get @qm_cau_tab

    get "/discussions/1/posts", {format: 'json'}
    assert_response :success
    assert_not_nil assigns(:posts)
  end

  ## API - Mobilis
  test "nao lista posts novos do forum da turma QM MAR de quimica" do
    get @qm_mar_tab

    get "/discussions/1/posts", {format: 'json'}
    assert_response :unauthorized
    assert_nil assigns(:posts)
  end

end