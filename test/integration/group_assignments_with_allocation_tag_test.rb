require 'test_helper'

class GroupAssignmentsWithAllocationTagTest < ActionDispatch::IntegrationTest
  def setup
    @quimica_tab  = add_tab_path(id: 3, context:2, allocation_tag_id: 3)  # QM CAU
    @quimica2_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 11) # QM MAR

    @aluno1, @prof, @editor, @user, @tutor, @aluno3 = users(:aluno1), users(:professor), users(:editor), users(:user), users(:tutor_distancia), users(:aluno3)
    @atividadeG1, @atividadeG2, @atividadeG3, @atividadeG4 = assignments(:a5), assignments(:a4), assignments(:a6), assignments(:a11)
    @groupG1, @groupG2, @groupG3, @groupG4, @groupG5 = group_assignments(:a5), group_assignments(:a4), group_assignments(:ga6), group_assignments(:ga8), group_assignments(:a1)
    # atividade G1 avaliada - grupo G1 (com aluno1 e aluno2)
    # atividade G2 - grupos g2 (com aluno user) e g5 (com aluno1 que enviou arquivo)
    # atividade G3 com prazo encerrado - grupo g3 (com alunos 1 e 2)
    # atividade G2 - grupo G4 é um grupo de um trabalho em grupo para QM-MAR
    # atividade G4 - não tem nada
  end

  ## Tela de gerência

  test "acessar tela de gerencia de grupos" do
    login @prof
    get @quimica_tab

    get group_assignments_path assignment_id: @atividadeG1
    assert_response :success
  end

  ## Acréscimo de participantes a um grupo

  test "adicionar participante a grupo" do
    login @prof
    get @quimica_tab

    assert_difference("GroupParticipant.count") do
      put add_participant_group_assignment_path id: @groupG2.id, user_id: @aluno3.id
    end

    assert_response :success
  end

  test "nao adicionar participante a grupo - grupo ja avaliado" do
    login @prof
    get @quimica_tab

    assert_no_difference("GroupParticipant.count") do
      put add_participant_group_assignment_path id: @groupG1.id, user_id: @aluno3.id
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("group_assignments.error.evaluated"), get_json_response("alert")
  end

  test "nao adicionar participante a grupo - periodo encerrado" do
    login @prof
    get @quimica_tab

    assert_no_difference("GroupParticipant.count") do
      put add_participant_group_assignment_path id: @groupG3.id, user_id: @aluno3.id
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("group_assignments.error.date_range_expired"), get_json_response("alert")
  end

  test "nao adicionar participante a grupo - sem acesso" do
    login @tutor
    get @quimica2_tab

    assert_no_difference("GroupParticipant.count") do
      put add_participant_group_assignment_path id: @groupG4.id, user_id: @aluno3.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao adicionar participante a grupo - sem permissao" do
    login @aluno1
    get @quimica_tab

    assert_no_difference("GroupParticipant.count") do
      put add_participant_group_assignment_path id: @groupG3.id, user_id: @aluno1.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  ## Remoção de participantes de um grupo

  test "remover participante de grupo" do
    login @prof
    get @quimica_tab

    assert_difference("GroupParticipant.count", -1) do
      put remove_participant_group_assignment_path id: @groupG2.id, user_id: @user.id
    end

    assert_response :success
  end

  test "nao remover participante de grupo - grupo ja avaliado" do
    login @prof
    get @quimica_tab

    assert_no_difference("GroupParticipant.count") do
      put remove_participant_group_assignment_path id: @groupG1.id, user_id: @aluno1.id
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("group_assignments.error.evaluated"), get_json_response("alert")
  end

  test "nao remover participante de grupo - periodo encerrado" do
    login @prof
    get @quimica_tab

    assert_no_difference("GroupParticipant.count") do
      put remove_participant_group_assignment_path id: @groupG3.id, user_id: @aluno1.id
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("group_assignments.error.date_range_expired"), get_json_response("alert")
  end

  test "nao remover participante de grupo - aluno ja enviou arquivo" do
    login @prof
    get @quimica_tab

    assert_no_difference("GroupParticipant.count") do
      put remove_participant_group_assignment_path id: @groupG5.id, user_id: @aluno1.id
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("group_assignments.error.has_files"), get_json_response("alert")
  end

  test "nao remover participante de grupo - sem permissao" do
    login @aluno1
    get @quimica_tab

    assert_no_difference("GroupParticipant.count") do
      put remove_participant_group_assignment_path id: @groupG5.id, user_id: @aluno1.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao remover participante de grupo - sem acesso" do
    login @tutor
    get @quimica2_tab

    assert_no_difference("GroupParticipant.count") do
      put remove_participant_group_assignment_path id: @groupG4.id, user_id: @user.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  ## Novo grupo

  test "criar novo grupo" do
    login @prof
    get @quimica_tab

    assert_difference("GroupAssignment.count") do
      post group_assignments_path assignment_id: @atividadeG2.id
    end

    assert_response :success
  end

  test "nao criar novo grupo - sem acesso" do
    login @tutor
    get @quimica2_tab
    
    assert_no_difference("GroupAssignment.count") do
      post group_assignments_path assignment_id: @atividadeG2.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao criar novo grupo - sem permissao" do
    login @aluno1
    get @quimica_tab


    assert_no_difference("GroupAssignment.count") do
      post group_assignments_path assignment_id: @atividadeG2.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  ## Renomear grupo

  test "renomear grupo" do
    login @prof
    get @quimica_tab

    put group_assignment_path id: @atividadeG2, group_assignments: {group_name: "Novo nome"}

    assert_response :success
  end

  test "nao renomear grupo - sem permissao" do
    login @aluno1
    get @quimica_tab

    put group_assignment_path id: @atividadeG2, group_assignments: {group_name: "Novo nome"}

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao renomear grupo - sem acesso" do
    login @tutor
    get @quimica2_tab

    put group_assignment_path id: @groupG2.id, group_assignments: {group_name: "Novo nome"}

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  ## Remover grupo

  test "remover grupo" do
    login @prof
    get @quimica_tab

    assert_difference("GroupParticipant.count", -1) do
      delete group_assignment_path id: @groupG2.id
    end

    assert_response :success
  end

  test "nao remover grupo - ja avaliado" do
    login @prof
    get @quimica_tab

    assert_no_difference("GroupParticipant.count") do
      delete group_assignment_path id: @groupG1.id
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("group_assignments.error.cant_remove"), get_json_response("alert")
  end

  test "nao remover grupo - com arquivos" do
    login @prof
    get @quimica_tab

    assert_no_difference("GroupParticipant.count") do
      delete group_assignment_path id: @groupG5.id
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("group_assignments.error.cant_remove"), get_json_response("alert")
  end

  test "nao remover grupo - sem permissao" do
    login @aluno1
    get @quimica_tab

    assert_no_difference("GroupParticipant.count") do
      delete group_assignment_path id: @groupG2.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao remover grupo - sem acesso" do
    login @tutor
    get @quimica2_tab

    assert_no_difference("GroupParticipant.count") do
      delete group_assignment_path id: @groupG4.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  ## Importar grupos

  test "importar grupos e participantes" do
    login @prof
    get @quimica_tab

    assert_difference("GroupParticipant.count", 3) do
      assert_difference("GroupAssignment.count", 2) do
        post import_group_assignment_path id: @atividadeG4.id, assignment_id: @atividadeG1.id
      end
    end

    assert_response :success
  end

  test "nao importar grupos e participantes - periodo encerrado" do
    login @prof
    get @quimica_tab

    assert_no_difference(["GroupParticipant.count", "GroupAssignment.count"]) do
      post import_group_assignment_path id: @atividadeG3.id, assignment_id: @atividadeG1.id
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("group_assignments.error.date_range_expired"), get_json_response("alert")
  end

  test "nao importar grupos e participantes - sem permissao" do
    login @aluno1
    get @quimica_tab

    assert_no_difference(["GroupParticipant.count", "GroupAssignment.count"]) do
      post import_group_assignment_path id: @atividadeG3.id, assignment_id: @atividadeG1.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao importar grupos e participantes - sem acesso" do
    login @tutor
    get @quimica2_tab

    assert_no_difference(["GroupParticipant.count", "GroupAssignment.count"]) do
      post import_group_assignment_path id: @atividadeG2.id, assignment_id: @atividadeG1.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

end
