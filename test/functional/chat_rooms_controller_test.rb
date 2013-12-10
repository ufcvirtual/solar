require 'test_helper'

class ChatRoomsControllerTest < ActionController::TestCase

  fixtures :chat_participants

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)
    @aluno1 = users(:aluno1)
  end

   test "listar" do
    get :index, {allocation_tags_ids: [3, 11, 22]}

    assert_response :success
    assert_not_nil assigns(:chat_rooms)
  end

  test "sem permissao - nao listar" do
    sign_in @aluno1

    get :index, {allocation_tags_ids: [3, 11, 22]}

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "criar sem participants" do
    assert_difference(["ChatRoom.count", "Schedule.count"]) do
      assert_no_difference("ChatParticipant.count") do
        post :create, {allocation_tags_ids: "3, 11, 22", chat_room: {title: "Chat 01", start_hour: "10:10", end_hour: "10:12", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day}}}
      end
    end

    assert_response :success
  end

  test "criar com participants" do
    assert_difference(["ChatRoom.count", "Schedule.count"]) do
      assert_difference("ChatParticipant.count", 2) do
        post :create, {allocation_tags_ids: "3, 11, 22", chat_room: {title: "Chat 01", start_hour: "10:10", end_hour: "10:12", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day}, 
        participants_attributes: {"0" => {_destroy: 0, allocation_id: 2}, "1" => {_destroy: 0, allocation_id: 19}}}}
        # Usuário do Sistema e Aluno 3
      end
    end

    assert_response :success
  end

  test "sem permissao - nao criar" do
    sign_in @aluno1

    assert_no_difference(["ChatRoom.count", "Schedule.count", "ChatParticipant.count"]) do
      post :create, {allocation_tags_ids: "3, 11, 22", chat_room: {title: "Chat 01", start_hour: "10:10", end_hour: "10:12", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day}}}
    end

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "editar alterando participantes" do
    assert_no_difference(["ChatRoom.count", "Schedule.count"]) do
      assert_difference("ChatParticipant.count", -1) do # remove 2 e adiciona 1
        put :update, {id: chat_rooms(:chat2).id, allocation_tags_ids: "3, 11, 22", chat_room: { 
          participants_attributes: {"0" => {_destroy: 1, allocation_id: 2, id: chat_participants(:participant_chat2_user).id}, 
                                    "1" => {_destroy: 0, allocation_id: 19, id: chat_participants(:participant_chat2_aluno3).id},
                                    "2" => {_destroy: 1, allocation_id: 11, id: chat_participants(:participant_chat2_aluno1).id},
                                    "3" => {_destroy: 0, allocation_id: 15}
                                   }
        }}
      end
    end

    participants = ChatParticipant.find_all_by_chat_room_id(chat_rooms(:chat2).id)
    assert (not participants.include?(chat_participants(:participant_chat2_user).id)) # verifica remoção do "user"
    assert (not participants.include?(chat_participants(:participant_chat2_aluno1).id)) # verifica remoção do "aluno1"
    assert (participants.include?(ChatParticipant.find_by_allocation_id_and_chat_room_id(15, chat_rooms(:chat2).id))) # verifica acréscimo do "aluno2"

    assert_response :success
  end

  test "sem permissao - nao editar" do
    sign_in @aluno1

    assert_no_difference(["ChatRoom.count", "Schedule.count", "ChatParticipant.count"]) do
      put :update, {id: chat_rooms(:chat2).id, allocation_tags_ids: "3, 11, 22", chat_room: { 
        participants_attributes: {"0" => {_destroy: 1, allocation_id: 2, id: chat_participants(:participant_chat2_user).id}, 
                                  "1" => {_destroy: 0, allocation_id: 19, id: chat_participants(:participant_chat2_aluno3).id},
                                  "2" => {_destroy: 1, allocation_id: 11, id: chat_participants(:participant_chat2_aluno1).id},
                                  "3" => {_destroy: 0, allocation_id: 15}
                                 }
      }}
    end

    assert_equal chat_rooms(:chat2).participants, ChatParticipant.find_all_by_chat_room_id(chat_rooms(:chat2).id)

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "nao criar chat para oferta ou uc ou curso" do
    chat_room = {title: "Chat 01", start_hour: "10:10", end_hour: "10:12", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day}}
    params_of = {chat_room: chat_room, allocation_tags_ids: allocation_tags(:al6)} 
    params_uc = {chat_room: chat_room, allocation_tags_ids: allocation_tags(:al13)}
    params_c  = {chat_room: chat_room, allocation_tags_ids: allocation_tags(:al19)}

    # tentando alocar para a UC de quimica 3 e o curso de licenciatura em quimica e para a oferta existente para curso e uc de quimica
    assert_no_difference(["ChatRoom.count", "Schedule.count"]) do
      post(:create, params_of)
      post(:create, params_uc)
      post(:create, params_c)
    end

    assert_response :unprocessable_entity
  end

=begin
  test "deletar" do
    assert_difference(["ChatRoom.count", "Schedule.count"]) do
      assert_difference("ChatParticipant.count", 2) do
        post :create, {allocation_tags_ids: "3, 11, 22", chat_room: {title: "Chat 01", start_hour: "10:10", end_hour: "10:12", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day}, 
        participants_attributes: {"0" => {_destroy: 0, allocation_id: 2}, "1" => {_destroy: 0, allocation_id: 19}}}}
        # Usuário do Sistema e Aluno 3
      end
    end

    chat = ChatRoom.last

    assert_difference(["ChatRoom.count", "Schedule.count"], -1) do
      assert_difference("ChatParticipant.count", -(chat.participants.count)) do
        delete :destroy, {allocation_tags_ids: [3, 11, 22], id: chat.id}
      end
    end

    assert_response :success
  end
=end

  test "sem permissao - nao deletar" do
    sign_in @aluno1

    assert_no_difference(["ChatRoom.count", "ChatParticipant.count"]) do
      delete :destroy, {allocation_tags_ids: [3, 11, 22], id: chat_rooms(:chat2).id}
    end

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "edicao - ver detalhes" do
    get(:show, {id: chat_rooms(:chat2).id, allocation_tags_ids: [allocation_tags(:al3).id]})
    assert_template :show
  end

  test "edicao - ver detalhes - aluno" do
    sign_in users(:aluno1)
    get(:show, {id: chat_rooms(:chat2).id, allocation_tags_ids: [allocation_tags(:al3).id]})
    assert_template :show
  end

end