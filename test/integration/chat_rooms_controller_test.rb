require 'test_helper'
 
# Aqui estão os testes dos métodos do controller scores
# que, para acessá-los, se faz necessário estar em uma unidade
# curricular. Logo, há a necessidade de acessar o método
# "add_tab" de outro controller. O que não é permitido em testes
# funcionais.

class ChatRoomsControllerTest < ActionDispatch::IntegrationTest
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