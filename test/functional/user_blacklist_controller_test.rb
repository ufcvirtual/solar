require 'test_helper'

class UserBlacklistControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:admin)
  end

  test "rotas" do
    assert_routing({method: :get, path: "/admin/blacklist"}, {controller: "user_blacklist", action: "index"})
    assert_routing({method: :get, path: "/admin/blacklist/search"}, {controller: "user_blacklist", action: "search"})

    assert_routing({method: :post, path: "/admin/blacklist"}, {controller: "user_blacklist", action: "create"})
    assert_routing({method: :post, path: "/admin/blacklist/add_user/1"}, {controller: "user_blacklist", action: "add_user", user_id: '1'})

    assert_routing({method: :delete, path: "/admin/blacklist/remove_user/87513981922"}, {controller: "user_blacklist", action: "destroy", user_cpf: '87513981922', type: 'remove'})
  end

  test "list" do
    get :index

    assert_response :success
    assert_not_nil assigns(:user_blacklist)
  end

  test "adicionar CPF a blacklist" do 
    assert_difference(["UserBlacklist.count"], 1) do
      post :create, {user_blacklist: {cpf: '20943068363', name: 'Owen B. Wilken'}}
    end

    assert_response :success
  end

  test "remover CPF da blacklist" do
    user_bl = user_blacklist(:user_bl1)

    assert_difference("UserBlacklist.count", -1) do
      delete :destroy, {id: user_bl.id}
    end
  end

end
