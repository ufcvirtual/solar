require 'test_helper'

class CurriculumUnitsWithLessonsTest < ActionDispatch::IntegrationTest

  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers

  def setup
    login_as users(:aluno1), scope: :user

    @quimica_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 6)
    @teoria_lite = add_tab_path(id: 2, context:2, allocation_tag_id: 5)
  end

  ##
  # Acessar aulas
  ##

  test "acessar aula tipo link como aluno" do
    get @quimica_tab

    get lesson_path(4)
    assert_response :success
  end

  test "acessar aula tipo arquivo como aluno" do
    get @teoria_lite

    get lesson_path(7)
    assert_response :success
  end

  test "nao acessar aula sem acessar oferta primeiro" do
    get lesson_path(4)
    assert_response :redirect

    assert_equal flash[:alert], I18n.t(:object_not_found)
  end

end
