require 'test_helper'

class AssignmentsWithAllocationTagTest < ActionDispatch::IntegrationTest
  def setup
    @quimica_tab  = add_tab_path(id: 3, context:2, allocation_tag_id: 3)  # QM CAU
    @quimica2_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 11) # QM MAR

    @aluno1, @prof, @editor, @user, @tutor = users(:aluno1), users(:professor), users(:editor), users(:user), users(:tutor_distancia)
    @atividadeI, @atividadeG, @group = assignments(:a3), assignments(:a5), group_assignments(:a5)
  end

  ## List

  test "listar atividades de uma turma" do
    login @aluno1
    get @quimica_tab

    get list_assignments_path
    assert_response :success
    assert assigns(:student)
    assert not(assigns(:can_manage))
    assert not(assigns(:can_import))

    login @prof
    get @quimica_tab

    get list_assignments_path
    assert_response :success
    assert not(assigns(:student))
    assert assigns(:can_manage)
    assert assigns(:can_import)
  end

  test "nao listar atividades de uma turma - sem permissao" do
    login @editor
    get @quimica_tab

    get list_assignments_path
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  test "nao listar atividades de uma turma - sem acesso" do
    login @aluno1
    get @quimica2_tab

    get list_assignments_path
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ## Student

  test "visualizar pagina com informacoes de aluno" do
    login @aluno1
    get @quimica_tab

    get student_assignment_path id: @atividadeI.id, student_id: @aluno1.id
    assert_response :success
    assert assigns(:own_assignment)
    assert_not_nil assigns(:in_time)
    assert_not_nil assigns(:sent_assignment)

    login @prof
    get @quimica_tab

    get student_assignment_path id: @atividadeI.id, student_id: @aluno1.id
    assert_response :success
    assert not(assigns(:own_assignment))
    assert_not_nil assigns(:in_time)
    assert_not_nil assigns(:sent_assignment)
  end

  test "visualizar pagina com informacoes de grupo" do
    login @aluno1
    get @quimica_tab

    get student_assignment_path id: @atividadeG.id, group_id: @group.id
    assert_response :success
    assert assigns(:own_assignment)
    assert_not_nil assigns(:in_time)
    assert_not_nil assigns(:sent_assignment)

    login @prof
    get @quimica_tab

    get student_assignment_path id: @atividadeG.id, group_id: @group.id
    assert_response :success
    assert not(assigns(:own_assignment))
    assert_not_nil assigns(:in_time)
    assert_not_nil assigns(:sent_assignment)
  end

  test "nao visualizar pagina com informacoes de aluno - sem acesso" do
    login @user
    get @quimica_tab

    get student_assignment_path id: @atividadeI.id, student_id: @aluno1.id
    assert not(assigns(:own_assignment))
    assert_nil assigns(:sent_assignment)
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  test "nao visualizar pagina com informacoes de grupo - sem acesso" do
    login @user
    get @quimica_tab

    get student_assignment_path id: @atividadeG.id, group_id: @group.id
    assert not(assigns(:own_assignment))
    assert_nil assigns(:sent_assignment)
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  test "nao visualizar pagina com informacoes de aluno - sem permissao" do
    login @editor
    get @quimica_tab

    get student_assignment_path id: @atividadeI.id, student_id: @aluno1.id
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ## Evaluate

  test "avaliar trabalho de aluno" do
    login @tutor
    get @quimica_tab

    put evaluate_assignment_path id: @atividadeI.id, student_id: @aluno1.id, grade: "5"
    assert_response :success
    assert_equal get_json_response("notice"), I18n.t("assignments.success.evaluated")
  end

  test "avaliar trabalho de grupo" do
    login @tutor
    get @quimica_tab

    put evaluate_assignment_path id: @atividadeG.id, group_id: @group.id, grade: "5"
    assert_response :success
    assert_equal get_json_response("notice"), I18n.t("assignments.success.evaluated")
  end

  test "nao avaliar trabalho de aluno - sem acesso" do
    login @tutor
    get @quimica2_tab

    put evaluate_assignment_path id: assignments(:a13).id, student_id: @aluno1.id, grade: "0"
    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

  test "nao avaliar trabalho de aluno - sem permissao" do
    login @aluno1
    get @quimica_tab

    put evaluate_assignment_path id: @atividadeI.id, student_id: @aluno1.id, grade: "10"
    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

end