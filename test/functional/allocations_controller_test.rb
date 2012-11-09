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

    al_matriculado = assigns(:allocations).select {|al| al.user_id == users(:user).id and al.status == Allocation_Activated and al.allocation_tag_id == allocation_tags(:al1).id}.first

    # o aluno User, esta matriculado na turma?
    assert not(al_matriculado.nil?)

    get :edit, :id => al_matriculado.id
    assert_response :success

    put :update, {:id => al_matriculado.id, :allocation => {:status => Allocation_Cancelled}}
    assert_response :success

    assert_select 'td', {:html => "Cancelado"}
  end

  test "exibir usuarios alocados para um usuario com permissao" do
    get :designates, { :allocation_tag_id => allocation_tags(:al5).id }
    assert_response :success
    assert_not_nil assigns(:allocations)

    assert_select "table tbody tr:nth-child(1)" do
      assert_select 'td:nth-child(1)', {:html => "Aluno 3"}
      assert_select 'td:nth-child(4)', {:html => "Prof. Titular"}
      assert_select 'td:nth-child(5) input[type=submit]', {:value => "Ativar"}
    end

    assert_select "table tbody tr:nth-child(2)" do
      assert_select 'td:nth-child(1)', {:html => "Professor"}
      assert_select 'td:nth-child(4)', {:html => "Prof. Titular"}
      assert_select 'td:nth-child(5) input[type=submit]', {:value => "Desativar"}
    end
  end

  test "ativar perfil inativo de usuario" do
    get :activate, { :id => allocations(:ad).id }
    assert_redirected_to({:action => :designates, :allocation_tag_id => allocations(:ad).allocation_tag_id })
    assert_equal I18n.t(:activated_user), flash[:notice]
  end

  test "desativar perfil de usuario" do
    get :deactivate, { :id => allocations(:g).id }
    assert_redirected_to({:action => :designates, :allocation_tag_id => allocations(:g).allocation_tag_id })
    assert_equal I18n.t(:deactivated_user), flash[:notice]
  end

  test "alocar usuario com perfil tutor a distancia" do
    post :create, { :allocation_tag_id => allocation_tags(:al5).id, :user_id => users(:user2).id, :profile => profiles(:tutor_distancia).id, :status => Allocation_Activated }
    assert_redirected_to({:action => :designates, :allocation_tag_id => allocation_tags(:al5).id })
  end

  # test "mudar aluno de turma" do

  #   get :index
  #   assert_response :success

  #   @allocations = assigns(:allocations)
  #   assert_not_nil @allocations

  #   raise "#{@allocations}"

  # end

end
