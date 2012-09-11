require 'test_helper'

class AllocationsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  test "listagem de pedidos de matricula por um usuario com permissao" do
    sign_in users(:coorddisc)

    get :index
    assert_response :success
    assert_not_nil assigns(:allocations)
  end

  test "listagem de pedidos de matricula por um usuario sem permissao" do
    sign_in users(:aluno1)

    get :index
    assert_response :redirect
  end

  test "seletor" do
    sign_in users(:coorddisc)

    get :index
    assert_response :success

    assert_select '.filter_counter', "(Total: 4 alunos)"
    # assert_select '#status_id', "Pendente"
  end


end
