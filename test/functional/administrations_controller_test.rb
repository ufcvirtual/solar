require 'test_helper'

class AdministrationsControllerTest < ActionController::TestCase
  
  include Devise::TestHelpers

  def setup
    @admin  = users(:admin)
    @editor = users(:editor)
    @aluno1 = users(:aluno1)
    sign_in @admin
  end

  test "acessar pagina de administracao de usuario" do
    get :users
    assert_response :success
  end

  test "nao acessar administracao de usuario sem permissao" do 
    sign_in @editor
    get :users
    assert_response :redirect
    assert_redirected_to home_path
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "buscar usuario" do
    get :search_users, user: 'aluno 1', type_search: 'name'
    assert_not_nil assigns(:users)
    assert_equal users(:aluno1).name, assigns(:users).first.name
  end

  test "nao buscar usuario sem permissao" do 
    sign_in @editor
    get :search_users, user: 'aluno 1', type_search: 'name'
    assert_nil assigns(:users)
    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

  test "buscar usuario nao retorna dados" do
    get :search_users, user: 'aluno xyz', type_search: 'name'
    assert assigns(:users).empty?
  end

  test "editar usuario" do
    assert_no_difference(["User.count"]) do
      put :update_user, { id: @aluno1.id, data: {name: "aluno1 alterado"}} 
    end

    assert_equal "aluno1 alterado", User.find(@aluno1.id).name
  end

  test "nao editar usuario sem permissao" do 
    sign_in @editor
    
    assert_no_difference(["User.count"]) do
      put :update_user, { id: @aluno1.id, data: { name: "aluno1 alterado", email: 'aluno1@solar.ufc.br'}}
    end
    assert_not_equal "aluno1 alterado", User.find(@aluno1.id).name

    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

  test "editar status de alocacao de usuario" do
    allocation = allocations(:aluno3_al8)
    assert_no_difference(["Allocation.count"]) do
      put :update_allocation, { id: allocation.id, status: Allocation_Cancelled}
    end

    assert_equal Allocation.find(allocation.id).status, Allocation_Cancelled
  end

  test "nao editar status de alocacao sem permissao" do 
    sign_in @editor
    
    allocation = allocations(:aluno3_al8)
    assert_no_difference(["Allocation.count"]) do
      put :update_allocation, { id: allocation.id, status: Allocation_Cancelled}
    end

    assert_not_equal Allocation.find(allocation.id).status, Allocation_Cancelled

    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

end
