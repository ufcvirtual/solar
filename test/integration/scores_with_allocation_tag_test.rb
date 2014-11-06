require 'test_helper'
 
class ScoresWithAllocationTagTest < ActionDispatch::IntegrationTest

  def setup
    @quimica_tab  = add_tab_path(id: 3, context:2, allocation_tag_id: 3)  # QM CAU
    @quimica2_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 11) # QM MAR
    @prof, @aluno, @tutor = users(:professor), users(:aluno1), users(:tutor_distancia)
  end

  test "visualizar acompanhamento da turma" do
    login @prof
    get @quimica_tab

    get scores_path
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:assignments)
    assert_not_nil assigns(:students)
    assert_not_nil assigns(:responsibles)
  end

  test "nao visualizar acompanhamento da turma - sem acesso" do
    login @tutor
    get @quimica2_tab

    get scores_path
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    assert_nil assigns(:assignments)
    assert_nil assigns(:students)
  end

  test "nao visualizar acompanhamento da turma - sem permissao" do
    login @aluno
    get @quimica_tab

    get scores_path
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    assert_nil assigns(:assignments)
    assert_nil assigns(:students)
  end

  test "visualizar acompanhamento de um aluno" do
    login @prof
    get @quimica_tab

    get user_info_scores_path(user_id: @aluno.id)
    assert_response :success
    assert_template :info
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:assignments)
    assert_not_nil assigns(:discussions)
    assert_not_nil assigns(:access)
  end

  test "nao visualizar acompanhamento de um aluno - sem permissao" do
    login @aluno
    get @quimica_tab

    get user_info_scores_path(user_id: @aluno.id)
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    assert_nil assigns(:user)
    assert_nil assigns(:assignments)
    assert_nil assigns(:discussions)
    assert_nil assigns(:access)
  end

  test "nao visualizar acompanhamento de um aluno - sem acesso" do
    login @tutor
    get @quimica2_tab

    get user_info_scores_path(user_id: @aluno.id)
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    assert_nil assigns(:user)
    assert_nil assigns(:assignments)
    assert_nil assigns(:discussions)
    assert_nil assigns(:access)
  end

  test "visualizar proprio acompanhamento" do
    login @aluno
    get @quimica_tab

    get info_scores_path(user_id: 8)
    assert_response :success
    assert_template :info
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:assignments)
    assert_not_nil assigns(:discussions)
    assert_not_nil assigns(:access)
    assert_equal assigns(:user), @aluno
  end
end
