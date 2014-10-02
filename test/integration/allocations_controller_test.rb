require 'test_helper'

class AllocationsControllerTest < ActionDispatch::IntegrationTest

  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers
  # para reconhecer o método "fixture_file_upload" no teste de integração
  include ActionDispatch::TestProcess

  def setup
    @coordenador = users(:coorddisc)
    @aluno1      = users(:aluno1)
    @admin       = users(:admin)
    @editor      = users(:editor)
    login(@coordenador)
    get home_path # acessa a home do usuário antes de qualquer ação
  end

  test "listar pedidos de matricula por um usuario com permissao" do
    get enrollments_allocations_path
    assert_response :success
    assert_not_nil assigns(:allocations)
  end

  test "listar pedidos de matricula por um usuario sem permissao" do
    login(users(:aluno1))

    get enrollments_allocations_path
    assert_response :redirect
  end

  # turma que o coordenador nao coordena
  test "nao exibir pedidos de matricula da turma CAU-A" do
    get enrollments_allocations_path
    assert_response :success

    assert_select "table tbody tr" do
      assert_select 'td:nth-child(3)', {count:  0, html:  "CAU-A - 2011.1"}
    end
  end

  test "aceitar matricula pendente do aluno user" do
    get enrollments_allocations_path
    assert_response :success

    al_pending = assigns(:allocations).select {|al| al.user_id == users(:user).id and al.status == Allocation_Pending}.first

    assert_select "table tbody tr" do
      assert_select 'td:nth-child(5)', {count: 1, html:  "Pendente"}
    end

    get edit_allocation_path(al_pending)
    assert_response :success

    assert_difference("LogAction.count") do
      put manage_enrolls_allocation_path, {id: al_pending.id, allocation: {status: Allocation_Activated}}
    end
    assert_response :success

    assert_select 'td', {html:  "Matriculado"}
  end

  test "rejeitar matricula pendente do aluno user" do
    get enrollments_allocations_path
    assert_response :success

    al_pending = assigns(:allocations).select {|al| al.user_id == users(:user).id and al.status == Allocation_Pending}.first

    assert_select "table tbody tr" do
      assert_select 'td:nth-child(5)', {count: 1, html: "Pendente"}
    end

    get edit_allocation_path(al_pending)
    assert_response :success

    assert_difference("LogAction.count") do
      put reject_allocation_path, {id: al_pending.id}
    end
    assert_response :success

    # assert_select 'td', {html:  "Rejeitado"}
  end

  test "cancelar matricula do aluno user na turma FOR - 2011.1" do
    get enrollments_allocations_path(status: 1) # lista de gerenciar matriculas
    assert_response :success

    al_matriculado = assigns(:allocations).select {|al| al.user_id == users(:user).id and al.status == Allocation_Activated and al.allocation_tag_id == allocation_tags(:al1).id}.first

    # o aluno User, esta matriculado na turma?
    assert not(al_matriculado.nil?)

    get edit_allocation_path(al_matriculado)
    assert_response :success

    assert_difference("LogAction.count") do
      put manage_enrolls_allocation_path, {id: al_matriculado.id, allocation: {status: Allocation_Cancelled}}
    end
    assert_response :success

    assert_select 'td', {html:  "Cancelado"}
  end

  test "exibir usuarios alocados para um usuario com permissao" do
    get designates_allocations_path, { allocation_tags_ids: "#{allocation_tags(:al5).id}" }
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
    login(users(:user2))

    get designates_allocations_path, { allocation_tags_ids:  "#{allocation_tags(:al5).id}" }
    assert_nil assigns(:allocations)
    assert_response :unauthorized
  end

  test "ativar perfil inativo de usuario" do
    assert_difference("LogAction.count") do
      put activate_allocation_path(allocations(:ad))
    end
    assert_response :success
  end

  test "nao ativar perfil inativo de usuario para usuario sem permissao" do
    login(users(:professor))

    assert_no_difference("LogAction.count") do
      put activate_allocation_path(allocations(:ad)), {format: :json}
    end

    assert_response :unauthorized
  end

  test "desativar perfil de usuario" do
    put deactivate_allocation_path(allocations(:g))
    assert_response :success
  end

  test "nao desativar perfil de usuario para usuario sem permissao" do
    login(users(:professor))

    assert_no_difference("LogAction.count") do
      put deactivate_allocation_path(allocations(:g)), {format: :json}
    end

    assert_response :unauthorized
  end

  test "alocar usuario com perfil tutor a distancia" do
    assert_difference(["Allocation.count", "LogAction.count"], 2) do
      post create_designation_allocations_path, { allocation_tags_ids:  "#{allocation_tags(:al5).id}", user_id: users(:user2).id, profile_id:  profiles(:tutor_distancia).id, status:  Allocation_Activated } #oferta
      post create_designation_allocations_path, { allocation_tags_ids:  "#{allocation_tags(:al4).id}", user_id: users(:user2).id, profile_id:  profiles(:tutor_distancia).id, status:  Allocation_Activated } #turma
    end

    assert_response :success
    assert allocation_tags(:al5).is_responsible?(users(:user2).id)
    assert allocation_tags(:al4).is_responsible?(users(:user2).id)
  end

  test "nao alocar usuario com perfil tutor a distancia para usuario sem permissao" do
    login(users(:professor))

    assert_no_difference(["Allocation.count", "LogAction.count"]) do
      post create_designation_allocations_path(format: :json), { allocation_tags_ids: "#{allocation_tags(:al5).id}", user_id:  users(:user2).id, profile_id:  profiles(:tutor_distancia).id, status: Allocation_Activated }
    end

    assert_response :unauthorized
    assert not(allocation_tags(:al5).is_responsible?(users(:user2).id))
  end

  # Admin
  test "alocar usuario como editor" do
    login(users(:admin))
    assert_difference(["Allocation.count", "LogAction.count"]) do
      post create_designation_allocations_path, { allocation_tags_ids:  "#{allocation_tags(:al5).id}", user_id: users(:user2).id, profile_id:  profiles(:editor).id, status:  Allocation_Activated , admin: true} #oferta
    end

    assert_response :success
    assert (not Allocation.where(user_id: users(:user2).id, profile_id: profiles(:editor).id, allocation_tag_id: allocation_tags(:al5).id).empty?)

    assert_difference(["Allocation.where(allocation_tag_id: 43).count", "LogAction.count"]) do
      post create_designation_allocations_path, { allocation_tags_ids:  "#{allocation_tags(:al43).id}", user_id: users(:user2).id, profile_id: profiles(:editor).id, status:  Allocation_Activated, admin: true } # uc_type
    end

    assert_response :success
  end

  test "nao alocar usuario com perfil editor - sem acesso" do
    login(users(:editor))
    assert_no_difference(["Allocation.where(allocation_tag_id: 43).count", "LogAction.count"]) do
      post create_designation_allocations_path, { allocation_tags_ids:  "#{allocation_tags(:al43).id}", user_id: users(:user2).id, profile_id: profiles(:editor).id, status: Allocation_Activated } # uc_type
    end
  end
  
  ##
  # Usuário solicitando matrícula
  ##

  # Usuário solicita matrícula dentro do período
  test "realizar pedido de matricula para aluno - dentro do periodo" do
    login(users(:editor))
    assert_difference(["Allocation.count", "LogAction.count"]) do
      post enroll_request_allocations_path(group_id: allocation_tags(:al1).group_id) # Introducao a linguistica
    end

    assert_response :success
    assert_equal I18n.t('allocations.request.success.enroll'), get_json_response("msg")
  end

  # Usuário solicita matrícula fora do período
  test "nao realizar pedido de matricula para aluno - fora do periodo" do
    login(users(:editor))
    assert_no_difference(["Allocation.count", "LogAction.count"]) do
      post enroll_request_allocations_path(group_id: allocation_tags(:al8).group_id) # literatura brasileria I
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t('allocations.request.error.enroll'), get_json_response("msg")
  end

  test "cancelar alocacao" do
    login(@coordenador)
    assert_difference("Allocation.where('status = 1').count", -1) do
      assert_no_difference("Allocation.count") do
        assert_difference("LogAction.count") do
          @request.env['HTTP_REFERER'] = "#{::Rails.root.to_s}/users/profiles"
          delete cancel_profile_request_allocation_path(@coordenador.allocations.where("allocation_tag_id IS NOT null").first), {format: :json}
        end
      end
    end

    assert_response :success

    assert_equal I18n.t('allocations.request.success.cancel_profile_request'), get_json_response("msg")
  end

  test "nao cancelar alocacao de outro usuario" do
    login(@aluno1)
    assert_no_difference(["Allocation.count", "LogAction.count"]) do
      @request.env['HTTP_REFERER'] = "#{::Rails.root.to_s}/users/profiles"
      delete cancel_profile_request_allocation_path(allocations(:h)), {format: :json}
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao cancelar alocacao com perfil de aluno" do
    login(@aluno1)
    assert_no_difference(["Allocation.count", "LogAction.count"]) do
      # alocação de aluno para aluno1 em allocation_tag_3
      @request.env['HTTP_REFERER'] = "#{::Rails.root.to_s}/users/profiles"
      delete cancel_profile_request_allocation_path(allocations(:l)), {format: :json}
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "solicitar nova alocacao geral" do
    login(@aluno1)
    assert_difference(["Allocation.count", "LogAction.count"]) do
      post profile_request_allocations_path(profile_id: profiles(:editor).id), format: :json
    end

    assert_equal Allocation.last.status, Allocation_Pending
    assert_response :success

    assert_equal I18n.t("allocations.request.success.profile"), get_json_response("msg")
  end

  test "solicitar nova alocacao em UC" do
    login(@aluno1)
    assert_difference(["Allocation.count", "LogAction.count"]) do
      post profile_request_allocations_path(profile_id: profiles(:editor).id, curriculum_unit_id: curriculum_units(:r2).id), format: :json
    end

    assert_equal Allocation.last.status, Allocation_Pending
    assert_response :success

    assert_equal I18n.t("allocations.request.success.profile"), get_json_response("msg")
  end

  test "solicitar alocacao ja ativa" do
    login(@coordenador)
    assert_no_difference(["Allocation.count", "LogAction.count"]) do
      post profile_request_allocations_path(profile_id: profiles(:editor).id, groups_id: "#{groups(:g5).id}"), format: :json
    end

    assert_equal "Perfil já está em uso", get_json_response("msg")
  end

  # Aceitar/Rejeitar solicitação de perfil

  test "aceitar solicitacao de perfil - admin" do
    login(@admin)
    allocation = allocations(:ad)

    assert_difference(["Allocation.where('status = #{Allocation_Activated}').count", "LogAction.count"]) do
      assert_difference("Allocation.where('status = #{Allocation_Pending}').count", -1) do
        put accept_allocation_path(allocations(:ad)), {accept: true}
      end
    end

    assert_response :success
    assert_match I18n.t("allocations.undo_action"), get_json_response("msg")
  end

  test "rejeitar solicitacao de perfil" do
    login(@admin)
    allocation = allocations(:ad)

    assert_difference(["Allocation.where('status = #{Allocation_Rejected}').count", "LogAction.count"]) do
      assert_difference("Allocation.where('status = #{Allocation_Pending}').count", -1) do
        put reject_allocation_path(allocation.id,), {pt: false}
      end
    end

    assert_response :success
    assert_match I18n.t("allocations.undo_action"), get_json_response("msg")
  end

  test "aceitar solicitacao de perfil - editor" do
    login(@editor)
    allocation = allocations(:ad)

    assert_difference(["Allocation.where('status = #{Allocation_Activated}').count", "LogAction.count"]) do
      assert_difference("Allocation.where('status = #{Allocation_Pending}').count", -1) do
        put accept_allocation_path(allocations(:ad))
      end
    end

    assert_response :success
    assert_match I18n.t("allocations.undo_action"), get_json_response("msg")
  end

  test "nao permitir aceitar solicitacao de perfil - sem relacao" do
    login(@editor)
    allocation = allocations(:editor_pending_as_admin)

    assert_no_difference(["Allocation.where('status = #{Allocation_Activated}').count", "LogAction.count"]) do
      assert_no_difference("Allocation.where('status = #{Allocation_Pending}').count") do
        put accept_allocation_path(allocations(:editor_pending_as_admin)), {format: :json}
      end
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "desfazer aceitacao de perfil" do
    login(@admin)
    allocation = allocations(:ad)
    put accept_allocation_path(allocations(:ad)), {accept: true}
    assert_equal Allocation_Activated, Allocation.find(allocation.id).status

    assert_difference("Allocation.where('status = #{Allocation_Activated}').count", -1) do
      assert_difference(["Allocation.where('status = #{Allocation_Pending}').count", "LogAction.count"]) do
        put undo_action_allocation_path(allocations(:ad)), {undo: true}
      end
    end

    assert_response :success
    assert_equal I18n.t("allocations.request.success.pending"), get_json_response("msg")
  end

  test "desfazer rejeicao de perfil" do
    login(@admin)
    allocation = allocations(:ad)
    put reject_allocation_path(allocations(:ad)), {accept: false}
    assert_equal Allocation_Rejected, Allocation.find(allocation.id).status

    assert_difference("Allocation.where('status = #{Allocation_Rejected}').count", -1) do
      assert_difference(["Allocation.where('status = #{Allocation_Pending}').count", "LogAction.count"]) do
        put undo_action_allocation_path(allocations(:ad)), {undo: true}
      end
    end

    assert_response :success
    assert_equal I18n.t("allocations.request.success.pending"), get_json_response("msg")
  end

end
