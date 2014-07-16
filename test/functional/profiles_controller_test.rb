require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase
  
  include Devise::TestHelpers

  def setup
    @admin  = users(:admin)
    @editor = users(:editor)
    @aluno1 = users(:aluno1)
    sign_in @admin
  end

  test "sem permissao - listagem de perfis" do
    sign_in @aluno1

    get :index
    assert_response :redirect
    assert_redirected_to home_path
  end

  test "cadastrar" do
    assert_difference(["Profile.count", "LogAction.count"], 1) do
      post :create, {profile: {name: "Lorem", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", template: nil}}
    end

    ## perfil nao tem nenhuma permissao
    assert assigns(:profile).resources.empty?
  end

  test "cadastrar com template" do
    assert_difference(["Profile.count", "LogAction.count"], 1) do
      post :create, {profile: {name: "Lorem", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", template: profiles(:admin).id}}
    end

    ## perfil ja tem permissoes
    assert not(assigns(:profile).resources.empty?)
  end

  test "nao cadastrar sem nome" do
    assert_no_difference(["Profile.count", "LogAction.count"]) do
      post :create, {profile: {description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", template: profiles(:admin).id}}
    end

    assert_template :new
  end

  test "editar" do
    profile_admin = profiles(:admin)

    assert_equal profile_admin.description, nil

    assert_no_difference("Profile.count") do
      assert_difference("LogAction.count") do
        put :update, {id: profile_admin.id, profile: {description: "poderes de super vaca"}}
      end
    end

    assert_equal assigns(:profile).description, "poderes de super vaca"
  end

  test "deletar" do
    assert_difference(["Profile.count"], 1) do
      post :create, {profile: {name: "Lorem", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", template: profiles(:admin).id}}
    end

    profile = assigns(:profile)

    assert_difference(["Profile.count"], -1) do
      assert_difference("LogAction.count") do
        delete :destroy, {id: profile.id}
      end
    end
  end

  test "listar permissoes" do
    get :permissions, {id: profiles(:admin).id}

    assert_response :success
    assert_not_nil assigns(:resources)
  end

  test "modificar permissoes de um perfil" do
    profile_admin = profiles(:admin)

    resources = profile_admin.resources

    assert resources.count > 0
    assert_difference("LogAction.count") do
      post :grant, {id: profile_admin.id, resources: [resources.first]}
    end

    assert profile_admin.resources.count == 1
  end

end
