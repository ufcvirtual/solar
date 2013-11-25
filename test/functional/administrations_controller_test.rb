require 'test_helper'

class AdministrationsControllerTest < ActionController::TestCase
  
  include Devise::TestHelpers

  def setup
    @editor = users(:editor)
    sign_in @editor
  end

  test "acessar pagina de administracao de usuario" do
    get :manage_user
    assert_response :success
  end

  # test "nao acessar administracao de usuario sem permissao" do 
  #   sign_out 
  #   sign_in users(:aluno1)
  #   get :manage_user
  #   assert_response :redirect
  #   assert_redirected_to home_path
  #   assert_equal flash[:alert], I18n.t(:no_permission)
  # end

  test "buscar usuario" do
    get :search_users, :user => 'aluno 1', :type_search => 0
    assert_not_nil assigns(:users)
    assert_equal users(:aluno1).name, assigns(:users).first.name
  end

  test "buscar usuario nao retorna dados" do
    get :search_users, :user => 'aluno xyz', :type_search => 0
    assert assigns(:users).empty?
  end

  test "editar usuario" do
    user = users(:aluno1)
    assert_no_difference(["User.count"]) do
      put :update_user, { id: user.id, name: "aluno1 alterado", email: 'email_aluno1@qq.com'}
    end

    assert_equal User.find(user.id).name, "aluno1 alterado"
  end

  test "editar status de alocacao de usuario" do
    allocation = allocations(:aluno3_al8)
    assert_no_difference(["Allocation.count"]) do
      put :update_allocation, { id: allocation.id, status: Allocation_Cancelled}
    end

    assert_equal Allocation.find(allocation.id).status, Allocation_Cancelled
  end

end
