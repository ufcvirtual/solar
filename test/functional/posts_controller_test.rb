require 'test_helper'

class PostsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:aluno1)
  end

  ## API - Mobilis
  test "rota de posts novos" do
    assert_routing "/discussions/1/posts/news/#{Date.today.to_s(:db)}", {
      :controller => "posts", :action => "index", :discussion_id => "1",
      :display_mode => "list", :type => "news", :date => Date.today.to_s(:db)
    }
  end

  ## API - Mobilis
  test "rota de posts antigos" do
    assert_routing "/discussions/1/posts/history/#{Date.today.to_s(:db)}", {
      :controller => "posts", :action => "index", :discussion_id => "1",
      :display_mode => "list", :type => "history", :date => Date.today.to_s(:db)
    }
  end

  ## API - Mobilis
  test "rota de posts novos com ordenacao" do
    assert_routing "/discussions/1/posts/news/#{Date.today.to_s(:db)}/order/asc", {
      :controller => "posts", :action => "index", :discussion_id => "1",
      :display_mode => "list", :type => "news", :date => Date.today.to_s(:db), :order => "asc"
    }
  end

  ## API - Mobilis
  test "rota de posts novos com ordenacao e limite" do
    assert_routing "/discussions/1/posts/news/#{Date.today.to_s(:db)}/order/asc/limit/10", {
      :controller => "posts", :action => "index", :discussion_id => "1",
      :display_mode => "list", :type => "news", :date => Date.today.to_s(:db), :order => "asc", :limit => "10"
    }
  end

  ## API - Mobilis
  test "rota para criar novo post" do
    assert_routing({:method => "post", :path => "/discussions/1/posts"}, {:controller => "posts", :action => "create", :discussion_id => "1"})
  end

  ## API - Mobilis
  test "rota para adicionar um arquivo ao post" do
    assert_routing({:method => "post", :path => "/posts/1/post_files"}, {:controller => "post_files", :action => "create", :post_id => "1"})
  end

  ## API - Mobilis
  test "rota para deletar post" do
    assert_routing({:method => "delete", :path => "/discussions/1/posts/1"}, {:controller => "posts", :action => "destroy", :discussion_id => "1", :id => "1"})
  end

  ## API - Mobilis
  test "lista posts novos do forum da turma FOR de introducao a linguistica" do
    get :index, {:format => 'json', :discussion_id => 1}
    assert_response :success
    assert_not_nil assigns(:posts)
  end

  ## API - Mobilis
  test "criar novo post no forum da turma FOR de introducao a linguistica" do
    discussion_id = 1
    assert_difference('Post.count') do
      post :create, :discussion_post => { :discussion_id => discussion_id, :content => "postagem de teste"}
    end

    assert_redirected_to discussion_posts_path(discussion_id)
  end

  ## API - Mobilis
  test "deletar post do forum da turma FOR de introducao a linguistica" do
    discussion_id = 1

    post(:create, :discussion_post => { :discussion_id => discussion_id, :content => "postagem de teste"})
    @post = assigns(:post)

    assert_difference('Post.count', -1) do
      delete :destroy, :id => @post
    end

    assert_response :success
  end

end
