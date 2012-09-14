require 'test_helper'

class AllocationsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    @coordenador = users(:coorddisc)
    sign_in @coordenador
  end

  test "listar pedidos de matricula por um usuario com permissao" do
    get :index
    assert_response :success
    assert_not_nil assigns(:allocations)
  end

  test "listar pedidos de matricula por um usuario sem permissao" do
    sign_out @coordenador
    sign_in users(:aluno1)

    get :index
    assert_response :redirect
  end

  test "exibir quantidade de alunos listados" do
    get :index
    assert_response :success

    assert_tag :select, :attributes => {:id => "status_id"}, :content => /Todos/
    assert_select '.filter_counter', "(Total: 4 alunos)"
  end

  # turma que o coordenador nao coordena
  test "nao exibir pedidos de matricula da turma CAU-A" do
    get :index
    assert_response :success

    assert_select "table tbody tr" do
      assert_select 'td:nth-child(3)', {:count => 0, :html => "CAU-A - 2011.1"}
    end
  end

  test "aceitar matricula pendente do aluno user" do
    get :index
    assert_response :success

    al_pending = assigns(:allocations).select {|al| al.user_id == users(:user).id and al.status == Allocation_Pending}.first

    assert_select "table tbody tr" do
      assert_select 'td:nth-child(4)', {:count => 1, :html => "Pendente"}
    end

    get :edit, :id => al_pending.id
    assert_response :success

    put :update, {:id => al_pending.id, :allocation => {:status => Allocation_Activated}}
    assert_response :success

    assert_select 'td', {:html => "Matriculado"}
  end

  test "rejeitar matricula pendente do aluno user" do
    get :index
    assert_response :success

    al_pending = assigns(:allocations).select {|al| al.user_id == users(:user).id and al.status == Allocation_Pending}.first

    assert_select "table tbody tr" do
      assert_select 'td:nth-child(4)', {:count => 1, :html => "Pendente"}
    end

    get :edit, :id => al_pending.id
    assert_response :success

    put :update, {:id => al_pending.id, :allocation => {:status => Allocation_Rejected}}
    assert_response :success

    assert_select 'td', {:html => "Rejeitado"}
  end

  test "cancelar matricula do aluno user na turma FOR - 2011.1" do
    get :index
    assert_response :success

    al_matriculado = assigns(:allocations).select {|al| al.user_id == users(:user).id and al.status == Allocation_Activated and al.allocation_tag_id == 1}

    # o aluno user esta matriculado na turma?
    assert (not al_matriculado.empty?)

    get :edit, :id => al_matriculado.first.id
    assert_response :success

    put :update, {:id => al_matriculado.first.id, :allocation => {:status => Allocation_Cancelled}}
    assert_response :success

    assert_select 'td', {:html => "Cancelado"}
  end

  test "mudar aluno de turma" do
    pending "mudar aluno de turma"
  end

end
