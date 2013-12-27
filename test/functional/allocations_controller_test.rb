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

    assert_tag :select, attributes: {id:  "status_id"}, content:  /Todos/
    assert_select '.filter_counter', "(Total: 4 alunos)"
  end

  # turma que o coordenador nao coordena
  test "nao exibir pedidos de matricula da turma CAU-A" do
    get :index
    assert_response :success

    assert_select "table tbody tr" do
      assert_select 'td:nth-child(3)', {count:  0, html:  "CAU-A - 2011.1"}
    end
  end

  test "aceitar matricula pendente do aluno user" do
    get :index
    assert_response :success

    al_pending = assigns(:allocations).select {|al| al.user_id == users(:user).id and al.status == Allocation_Pending}.first

    assert_select "table tbody tr" do
      assert_select 'td:nth-child(5)', {count: 1, html:  "Pendente"}
    end

    get :edit, id: al_pending.id
    assert_response :success

    put :update, {id: al_pending.id, allocation: {status: Allocation_Activated}}
    assert_response :success

    assert_select 'td', {html:  "Matriculado"}
  end

  test "rejeitar matricula pendente do aluno user" do
    get :index
    assert_response :success

    al_pending = assigns(:allocations).select {|al| al.user_id == users(:user).id and al.status == Allocation_Pending}.first

    assert_select "table tbody tr" do
      assert_select 'td:nth-child(5)', {count: 1, html: "Pendente"}
    end

    get :edit, id:  al_pending.id
    assert_response :success

    put :update, {id: al_pending.id, allocation: {status:  Allocation_Rejected}}
    assert_response :success

    assert_select 'td', {html:  "Rejeitado"}
  end

  test "cancelar matricula do aluno user na turma FOR - 2011.1" do
    get :index
    assert_response :success

    al_matriculado = assigns(:allocations).select {|al| al.user_id == users(:user).id and al.status == Allocation_Activated and al.allocation_tag_id == allocation_tags(:al1).id}.first

    # o aluno User, esta matriculado na turma?
    assert not(al_matriculado.nil?)

    get :edit, id: al_matriculado.id
    assert_response :success

    put :update, {id:  al_matriculado.id, allocation:  {status:  Allocation_Cancelled}}
    assert_response :success

    assert_select 'td', {html:  "Cancelado"}
  end

  test "exibir usuarios alocados para um usuario com permissao" do
    get :designates, { allocation_tags_ids: [allocation_tags(:al5).id] }
    assert_response :success
    assert_not_nil assigns(:allocations)

    assert_select "table tbody tr:nth-child(1)" do
      assert_select 'td:nth-child(1)', {html: "Aluno 3"}
      assert_select 'td:nth-child(4)', {html: "Prof. Titular"}
      assert_select 'button', {value: "Ativar"}
    end

    assert_select "table tbody tr:nth-child(2)" do
      assert_select 'td:nth-child(1)', {html: "Professor"}
      assert_select 'td:nth-child(4)', {html: "Prof. Titular"}
      assert_select 'button', {value: "Desativar"}
    end
  end

  test "nao exibir usuarios alocados para um usuario sem permissao" do
    sign_out @coordenador
    sign_in users(:user2)

    get :designates, { allocation_tags_ids:  [allocation_tags(:al5).id] }
    assert_nil assigns(:allocations)
    assert_response :unprocessable_entity
  end

  test "ativar perfil inativo de usuario" do
    get :activate, { id:  allocations(:ad).id }
    assert_response :success
  end

  test "nao ativar perfil inativo de usuario para usuario sem permissao" do
    sign_out @coordenador
    sign_in users(:professor)

    get :activate, { id:  allocations(:ad).id }
    assert_response :unprocessable_entity
  end

  test "desativar perfil de usuario" do
    get :deactivate, { id:  allocations(:g).id }
    assert_response :success
  end

  test "nao desativar perfil de usuario para usuario sem permissao" do
    sign_out @coordenador
    sign_in users(:professor)

    get :deactivate, { id:  allocations(:g).id }
    assert_response :unprocessable_entity
  end

  test "alocar usuario com perfil tutor a distancia" do
    assert_difference("Allocation.count", 2) do
      post :create_designation, { allocation_tags_ids:  [allocation_tags(:al5).id], user_id: users(:user2).id, profile:  profiles(:tutor_distancia).id, status:  Allocation_Activated } #oferta
      post :create_designation, { allocation_tags_ids:  [allocation_tags(:al4).id], user_id: users(:user2).id, profile:  profiles(:tutor_distancia).id, status:  Allocation_Activated } #turma
    end

    assert_response :success
    assert allocation_tags(:al5).is_user_class_responsible?(users(:user2).id)    
    assert allocation_tags(:al4).is_user_class_responsible?(users(:user2).id)    
  end

  test "nao alocar usuario com perfil tutor a distancia para usuario sem permissao" do
    sign_out @coordenador
    sign_in users(:professor)
    
    assert_no_difference("Allocation.count") do
      post :create_designation, { allocation_tags_ids: [allocation_tags(:al5).id], user_id:  users(:user2).id, profile:  profiles(:tutor_distancia).id, status:  Allocation_Activated }
    end
    
    assert_response :unprocessable_entity
    assert (not allocation_tags(:al5).is_user_class_responsible?(users(:user2).id))
  end

  # Admin
  test "alocar usuario como editor" do
    sign_in users(:admin)
    assert_difference("Allocation.count", 1) do
      post :create_designation, { allocation_tags_ids:  [allocation_tags(:al5).id], user_id: users(:user2).id, profile:  profiles(:editor).id, status:  Allocation_Activated , admin: true} #oferta
    end

    assert_response :success
    assert (not Allocation.where(user_id: users(:user2).id, profile_id: profiles(:editor).id, allocation_tag_id: allocation_tags(:al5).id).empty?)
  end

  # test "nao alocar usuario como editor parra usuario sem permissao" do
  #   sign_in users(:editor)
  #   assert_no_difference("Allocation.count") do
  #     post :create_designation, { allocation_tags_ids:  [allocation_tags(:al5).id], user_id: users(:user2).id, profile: profiles(:editor).id, status:  Allocation_Activated, admin: true } #oferta
  #   end

  #   assert_response :unprocessable_entity
  #   assert (Allocation.where(user_id: users(:user2).id, profile_id: profiles(:editor).id, allocation_tag_id: allocation_tags(:al5).id).empty?)
  # end

  ##
  # Usuário solicitando matrícula
  ##

  # Usuário solicita matrícula dentro do período
  test "realizar pedido de matricula para aluno - dentro do periodo" do
    sign_in users(:editor)
    assert_difference("Allocation.count", +1) do
      post :create, {allocation_tag_id: allocation_tags(:al5).id, user_id: users(:editor).id}
    end
    assert_response :redirect
    assert_equal flash[:notice], I18n.t(:enrollm_request, scope:  [:allocations, :success])
  end

  # Usuário solicita matrícula fora do período
  test "nao realizar pedido de matricula para aluno - fora do periodo" do
    sign_in users(:editor)
    assert_no_difference("Allocation.count") do
      post :create, {allocation_tag_id: allocation_tags(:al8).id, user_id: users(:editor).id}
    end
    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:enrollm_request, scope:  [:allocations, :error])
  end

  # test "mudar aluno de turma" do

  #   get :index
  #   assert_response :success

  #   @allocations = assigns(:allocations)
  #   assert_not_nil @allocations

  #   raise "#{@allocations}"

  # end


end
