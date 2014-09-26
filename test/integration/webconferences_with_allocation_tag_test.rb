require 'test_helper'

class WebconferencesWithAllocationTagTest < ActionDispatch::IntegrationTest

  def setup
    login_as users(:aluno1), scope: :user

    @quimica_tab = add_tab_path(id: 3, context: 2, allocation_tag_id: 3)
  end

  test "listagem para alunos e professores" do
    get @quimica_tab
    get webconferences_path

    assert_not_nil assigns(:webconferences)
    assert_response :success
  end

end
