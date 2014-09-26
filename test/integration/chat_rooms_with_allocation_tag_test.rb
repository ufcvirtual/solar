require 'test_helper'

class ChatRoomsWithAllocationTagTest < ActionDispatch::IntegrationTest
  def setup
    @quimica_tab               = add_tab_path(id: 3, context:2, allocation_tag_id: 3)
    @literatura_brasileira_tab = add_tab_path(id: 5, context:2, allocation_tag_id: 8)
  end

  test "lista mensagens" do
    login users(:aluno1)
    get @quimica_tab
    get messages_chat_room_path(chat_rooms(:chat3))

    assert_response :success
    assert_not_nil assigns(:messages)
    assert_equal assigns(:messages).size, 3
  end

  test "nao lista mensagen - sem acesso" do
    login users(:aluno1)
    get @literatura_brasileira_tab
    get messages_chat_room_path(chat_rooms(:chat2))

    assert_response :unauthorized
    assert_nil assigns(:messages)
  end

end