require 'test_helper'

class GroupsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)
    @aluno1 = users(:aluno1)
    @professor = users(:professor)
  end

  ## API - Mobilis
  test "lista de turmas da disciplina de introducao a linguistica" do
    sign_in @aluno1
    assert_routing '/curriculum_units/1/groups', {controller:  "groups", action:  "index", curriculum_unit_id:  "1"}

    get :index, {format: 'json', curriculum_unit_id: 1}
    assert_response :success
    assert_not_nil assigns(:groups)
  end

  ##
  # Destroy
  ##

  # Usuário com permissão e acesso (remove seu respectivo módulo default, pois não possui aulas)
  test "remover turma" do
    assert_difference(["Group.count", "LessonModule.count"], -1) do
      delete(:destroy, {id: groups(:g13).id, allocation_tags_ids: [allocation_tags(:al41).id]})
    end

    assert_response :success
  end

  # Usuário com permissão e acesso, mas a turma não permite (possui níveis inferiores)
  test "nao remove turma - niveis inferiores" do
    assert_no_difference(["Group.count", "LessonModule.count"]) do
      delete :destroy, {id: groups(:g1).id}
    end

    assert_response :unprocessable_entity
  end

  ########### Adicionar/Desvincular/Remover turma de uma ferramenta ###########

   ## Ações com sucesso ##

  # Chat
  test "desvincular turma a uma ferramenta - chat" do
    # g = Group.create(code: 'GROUP-TEST', offer_id: 3)

    chat_room2 = chat_rooms(:chat2)
    assert_difference("ChatRoom.count") do
      assert_no_difference("ChatParticipant.count") do
        assert_no_difference("AcademicAllocation.count") do
          put :change_tool, {id: "3", tool_type: "ChatRoom", tool_id: chat_room2.id, type: "unbind"}
        end
      end
    end

    assert_equal I18n.t(:unbind, scope: [:groups, :success]), get_json_response("notice")
    assert_response :success
  end

  test "adicionar turma a uma ferramenta - chat" do
    chat_room1 = chat_rooms(:chat1)
    assert_difference("AcademicAllocation.count") do
      assert_no_difference("ChatRoom.count") do
        put :change_tool, {id: "5", tool_type: "ChatRoom", tool_id: chat_room1.id, type: "add"}
      end
    end

    assert_equal I18n.t(:add, scope: [:groups, :success]), get_json_response("notice")
    assert_response :success
  end

  test "remover turma de uma ferramenta - chat" do
    chat_room2 = chat_rooms(:chat2)
    assert_no_difference("ChatRoom.count") do
      assert_difference("AcademicAllocation.count", -1) do
        put :change_tool, {id: "5", tool_type: "ChatRoom", tool_id: chat_room2.id, type: "remove"}
      end
    end

    assert_equal I18n.t(:remove, scope: [:groups, :success]), get_json_response("notice")
    assert_response :success
  end

  # Assignment
  test "desvincular turma a uma ferramenta - assignment" do
    # para a turma 3 (QM-CAU), o trabalho não tem nenhum sent_assignment
    atividade_grupo_I = assignments(:a11)
    assert_difference("Assignment.count") do
      assert_difference("AssignmentEnunciationFile.count", atividade_grupo_I.enunciation_files.size) do
        assert_no_difference("AcademicAllocation.count") do
          put :change_tool, {id: "3", tool_type: "Assignment", tool_id: atividade_grupo_I.id, type: "unbind"}
        end
      end
    end

    assert_equal I18n.t(:unbind, scope: [:groups, :success]), get_json_response("notice")
    assert_response :success
  end

  test "adicionar turma a uma ferramenta - assignment" do
    assignment9 = assignments(:a9)
    assert_difference("AcademicAllocation.count") do
      assert_no_difference("Assignment.count") do
        put :change_tool, {id: "5", tool_type: "Assignment", tool_id: assignment9.id, type: "add"}
      end
    end

    assert_equal I18n.t(:add, scope: [:groups, :success]), get_json_response("notice")
    assert_response :success
  end

  test "remover turma de uma ferramenta - assignment" do
    # para a turma 3 (QM-CAU), o trabalho não tem nenhum sent_assignment
    atividade_grupo_I = assignments(:a11)
    assert_no_difference("Assignment.count") do
      assert_difference("AcademicAllocation.count", -1) do
        put :change_tool, {id: "3", tool_type: "Assignment", tool_id: atividade_grupo_I.id, type: "remove"}
      end
    end


    assert_equal I18n.t(:remove, scope: [:groups, :success]), get_json_response("notice")
    assert_response :success
  end

  ## Ações com erro: sem permissão ##

  # Chat
  test "nao desvincular turma a uma ferramenta - permissao - chat" do
    sign_in @professor
    chat_room2 = chat_rooms(:chat2)
    assert_no_difference(["ChatRoom.count", "AcademicAllocation.count", "ChatParticipant.count"]) do
      put :change_tool, {id: "5", tool_type: "ChatRoom", tool_id: chat_room2.id, type: "unbind"}
    end

    assert_response :redirect
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  test "nao adicionar turma a uma ferramenta - permissao - chat" do
    sign_in @professor
    chat_room1 = chat_rooms(:chat1)
    assert_no_difference(["ChatRoom.count", "AcademicAllocation.count"]) do
      put :change_tool, {id: "5", tool_type: "ChatRoom", tool_id: chat_room1.id, type: "add"}
    end

    assert_response :redirect
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  test "nao remover turma de uma ferramenta - permissao - chat" do
    sign_in @professor
    chat_room2 = chat_rooms(:chat2)
    assert_no_difference(["ChatRoom.count", "AcademicAllocation.count"]) do
      put :change_tool, {id: "5", tool_type: "ChatRoom", tool_id: chat_room2.id, type: "remove"}
    end

    assert_response :redirect
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Assignment
  test "nao desvincular turma a uma ferramenta - permissao - assignment" do
    sign_in @professor
    atividade_grupo_I = assignments(:a11)
    assert_no_difference(["Assignment.count", "AssignmentEnunciationFile.count", "AcademicAllocation.count"]) do
      put :change_tool, {id: "3", tool_type: "Assignment", tool_id: atividade_grupo_I.id, type: "unbind"}
    end

    assert_response :redirect
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  test "nao adicionar turma a uma ferramenta - permissao - assignment" do
    sign_in @professor
    assignment9 = assignments(:a9)
    assert_no_difference(["Assignment.count", "AcademicAllocation.count"]) do
      put :change_tool, {id: "5", tool_type: "Assignment", tool_id: assignment9.id, type: "add"}
    end

    assert_response :redirect
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  test "nao remover turma de uma ferramenta - permissao - assignment" do
    sign_in @professor
    atividade_grupo_I = assignments(:a11)
    assert_no_difference(["Assignment.count", "AcademicAllocation.count"]) do
      put :change_tool, {id: "3", tool_type: "Assignment", tool_id: atividade_grupo_I.id, type: "remove"}
    end

    assert_response :redirect
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  ## Ações com erro: possui dependencias intransferíveis ##

  # Chat
  test "nao desvincular turma a uma ferramenta - unica turma - chat" do
    chat_room1 = chat_rooms(:chat1)
    assert_no_difference(["ChatRoom.count", "AcademicAllocation.count", "ChatParticipant.count"]) do
      put :change_tool, {id: "3", tool_type: "ChatRoom", tool_id: chat_room1.id, type: "unbind"}
    end

    assert_equal I18n.t(:last_group, scope: [:groups, :error]), get_json_response("alert")
    assert_response :unprocessable_entity
  end

  test "nao remover turma de uma ferramenta - unica turma - chat" do
    chat_room1 = chat_rooms(:chat1)
    assert_no_difference(["ChatRoom.count", "AcademicAllocation.count"]) do
      put :change_tool, {id: "3", tool_type: "ChatRoom", tool_id: chat_room1.id, type: "remove"}
    end

    assert_equal I18n.t(:last_group, scope: [:groups, :error]), get_json_response("alert")
    assert_response :unprocessable_entity
  end

  test "nao desvincular turma a uma ferramenta - dependencias - chat" do
    # chat3 possui mensagens
    chat_room3 = chat_rooms(:chat3)
    assert_no_difference(["ChatRoom.count", "AcademicAllocation.count", "ChatParticipant.count"]) do
      put :change_tool, {id: "3", tool_type: "ChatRoom", tool_id: chat_room3.id, type: "unbind"}
    end

    assert_equal I18n.t(:cant_transfer_dependencies, scope: [:groups, :error]), get_json_response("alert")
    assert_response :unprocessable_entity
  end

  test "nao remover turma de uma ferramenta - dependencias - chat" do
    # chat3 possui mensagens
    chat_room3 = chat_rooms(:chat3)
    assert_no_difference(["ChatRoom.count", "AcademicAllocation.count"]) do
      put :change_tool, {id: "3", tool_type: "ChatRoom", tool_id: chat_room3.id, type: "remove"}
    end

    assert_equal I18n.t(:cant_transfer_dependencies, scope: [:groups, :error]), get_json_response("alert")
    assert_response :unprocessable_entity
  end

  # Assignment
  test "nao desvincular turma a uma ferramenta - unica turma - assignment" do
    # o trabalho de id 4 só tem uma turma
    atividade_grupo_I = assignments(:a2)
    assert_no_difference(["AcademicAllocation.count", "AssignmentEnunciationFile.count", "Assignment.count"]) do
      put :change_tool, {id: "3", tool_type: "Assignment", tool_id: atividade_grupo_I.id, type: "unbind"}
    end

    assert_equal I18n.t(:last_group, scope: [:groups, :error]), get_json_response("alert")
    assert_response :unprocessable_entity
  end

  test "nao remover turma de uma ferramenta - unica turma - assignment" do
    # o trabalho de id 4 só tem uma turma
    atividade_grupo_I = assignments(:a2)
    assert_no_difference(["AcademicAllocation.count", "Assignment.count"]) do
      put :change_tool, {id: "3", tool_type: "Assignment", tool_id: atividade_grupo_I.id, type: "remove"}
    end

    assert_equal I18n.t(:last_group, scope: [:groups, :error]), get_json_response("alert")
    assert_response :unprocessable_entity
  end

  test "nao desvincular turma a uma ferramenta - dependencias - assignment" do
    # para a turma 5 (LB-CAR), o trabalho tem sent_assignment
    atividade_grupo_I = assignments(:a11)
    assert_no_difference(["AcademicAllocation.count", "AssignmentEnunciationFile.count", "Assignment.count"]) do
      put :change_tool, {id: "5", tool_type: "Assignment", tool_id: atividade_grupo_I.id, type: "unbind"}
    end

    assert_equal I18n.t(:cant_transfer_dependencies, scope: [:groups, :error]), get_json_response("alert")
    assert_response :unprocessable_entity
  end

  test "nao remover turma de uma ferramenta - dependencias - assignment" do
    # para a turma 5 (LB-CAR), o trabalho tem sent_assignment
    atividade_grupo_I = assignments(:a11)
    assert_no_difference(["Assignment.count", "AcademicAllocation.count"]) do
      put :change_tool, {id: "5", tool_type: "Assignment", tool_id: atividade_grupo_I.id, type: "remove"}
    end

    assert_equal I18n.t(:cant_transfer_dependencies, scope: [:groups, :error]), get_json_response("alert")
    assert_response :unprocessable_entity
  end

end
