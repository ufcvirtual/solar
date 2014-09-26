require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:user)
    login(@user)
    get home_path # acessa a home do usuário antes de qualquer ação
  end

  test "acessar pagina de perfis do usuario" do
    get profiles_users_path
    assert_not_nil assigns(:allocations)
    assert_equal assigns(:allocations).size, users(:user).allocations.count-1 # todas as alocações menos a básica

    assert_response :success
  end

  test "acessar tela de solicitação de perfil" do
    get request_profile_users_path

    assert_not_nil assigns(:allocation)
    assert_not_nil assigns(:types)
    assert_not_nil assigns(:profiles)

    assert_equal assigns(:profiles).size, Profile.all.count-2
  end

end