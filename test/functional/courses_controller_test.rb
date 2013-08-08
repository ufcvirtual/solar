require 'test_helper'

class CoursesControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    @aluno1, @editor = users(:aluno1), users(:coorddisc)
    sign_in @editor
  end

  test "listar" do
    get :index

    assert_response :success
    assert_not_nil assigns(:courses)
  end

  test "listar para combobox" do
    get :index, {combobox: true}

    assert_response :success
    assert_not_nil assigns(:courses)
  end

  test "sem permissao - nao listar" do
    sign_in @aluno1

    get :index

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "criar" do
    assert_difference("Course.count", 1) do
      post :create, {course: {code: "T1", name: "Teste 1"}}
    end

    assert_response :success
  end

  test "nao criar com codigo repetido" do
    assert_difference("Course.count", 1) do
      post :create, {course: {code: "T1", name: "Teste 1"}}
    end

    assert_no_difference("Course.count") do
      post :create, {course: {code: "T1", name: "Teste 1"}}
    end
  end

  test "sem permissao - nao criar" do
    sign_in @aluno1

    assert_no_difference("Course.count") do
      post :create, {course: {code: "T1", name: "Teste 1"}}
    end

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "editar" do
    assert_difference("Course.count", 1) do
      post :create, {course: {code: "T1", name: "Teste 1"}}
    end

    get :edit, {id: Course.where(code: "T1").first.id}
    assert_not_nil assigns(:course)
  end

  test "sem permissao - nao editar" do
    sign_in @aluno1

    get :edit, {id: Course.first.id}

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "deletar" do
    assert_difference("Course.count", 1) do
      post :create, {course: {code: "T1", name: "Teste 1"}}
    end

    assert_difference("Course.count", -1) do
      delete :destroy, {id: Course.where(code: "T1").first.id}
    end
  end

  test "com turmas - nao deletar mesmo com permissao" do
    quimica = courses(:c2).id

    assert_no_difference("Course.count") do
      delete :destroy, {id: quimica}
    end

    assert_response :unprocessable_entity
  end

  test "sem permissao - nao deletar" do
    sign_in @aluno1

    assert_no_difference("Course.count") do
      delete :destroy, {id: Course.first.id}
    end

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end
end
