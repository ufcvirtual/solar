require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  
  include Devise::TestHelpers

  def setup
    @user = users(:user)
    sign_in @user
  end

  test "acessar pagina de perfis do usuario" do
    get :profiles
    assert_not_nil assigns(:allocations)
    assert_equal assigns(:allocations).size, users(:user).allocations.count-1 # todas as alocações menos a básica

    assert_response :success
  end

  test "acessar tela de solicitação de perfil" do
    get :request_profile

    assert_not_nil assigns(:allocation)
    assert_not_nil assigns(:types)
    assert_not_nil assigns(:profiles)

    assert_equal assigns(:profiles).size, Profile.all.count-2
  end

end