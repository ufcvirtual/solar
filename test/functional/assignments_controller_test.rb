require 'test_helper'

class AssignmentsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  fixtures :allocation_tags, :assignments, :group_assignments, :users, :sent_assignments

  def setup
    sign_in users(:editor)
  end

  test "rotas" do
    ## apenas algumas rotas
    assert_routing({method: :get, path: "/assignments/student"}, {controller: "assignments", action: "student"})
    assert_routing({method: :get, path: "/assignments/professor"}, {controller: "assignments", action: "professor"})
    assert_routing({method: :post, path: "/assignments/upload_file"}, {controller: "assignments", action: "upload_file"})
    assert_routing({method: :delete, path: "/assignments/delete_file"}, {controller: "assignments", action: "delete_file"})
    assert_routing({method: :delete, path: "/assignments/1/remove_comment"}, {controller: "assignments", action: "remove_comment", id: "1"})
    assert_routing({method: :get, path: "/assignments"}, {controller: "assignments", action: "index"})
    assert_routing({method: :post, path: "/assignments"}, {controller: "assignments", action: "create"})
  end

  test "listar as atividiades de uma turma para usuario com permissao" do 
    sign_in users(:professor)
    get :professor
    assert_response :success
    assert_not_nil assigns(:individual_activities)
    assert_not_nil assigns(:group_activities)
    assert_template :professor
  end

  test "nao listar as atividiades de uma turma para usuario sem permissao" do 
    sign_in users(:aluno1)
    get :professor
    assert_response :redirect
    assert_redirected_to home_path
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  ##
  # Edicao
  ##

  test "edicao - listar trabalhos" do
    quimica = allocation_tags(:al3).id

    get :index, {allocation_tags_ids: [quimica]}
    assert_response :success
  end

  test "edicao - nao listar trabalhos para usuario sem permissao" do
    quimica = allocation_tags(:al3).id
    sign_in users(:aluno1)

    get :index, {allocation_tags_ids: [quimica]}

    assert_response :redirect
    assert_redirected_to home_path
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "edicao - criar trabalho sem arquivos no enunciado" do
    assert_difference(["Assignment.count", "Schedule.count"], 1) do
      assert_difference(["AcademicAllocation.count"], 3) do
        post :create, {allocation_tags_ids: "#{allocation_tags(:al3).id} #{allocation_tags(:al11).id} #{allocation_tags(:al22).id}", assignment: {name: "Testa modulo3", enunciation: "Assignment para testar modulo", type_assignment: 0, schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
      end
    end

    assert_response :success
  end

  test "edicao - criar trabalho com arquivos no enunciado para varias turmas de Quimica I" do
    assert_difference(["Assignment.count", "Schedule.count"], 1) do
      assert_difference(["AcademicAllocation.count", "AssignmentEnunciationFile.count"], 3) do
        post :create, {allocation_tags_ids: "#{allocation_tags(:al3).id} #{allocation_tags(:al11).id} #{allocation_tags(:al22).id}",
          assignment: {name: "Testa modulo3", enunciation: "Assignment para testar modulo", type_assignment: 0,
            schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month},
            enunciation_files_attributes: {
              "0" => {attachment: fixture_file_upload('files/file_10k.dat')},
              "1" => {attachment: fixture_file_upload('files/file_10k.dat')},
              "2" => {attachment: fixture_file_upload('files/file_10k.dat')}
            }}}
      end
    end

    assert_response :success
  end

  test "edicao - nao criar trabalho para oferta ou curso ou uc - modulo permite apenas turma" do
    params_offer  = {allocation_tags_ids: "#{allocation_tags(:al6).id}", assignment: {name: "Testa modulo1", enunciation: "Assignment para testar modulo", type_assignment: 0, schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
    params_uc     = {allocation_tags_ids: "#{allocation_tags(:al13).id}", assignment: {name: "Testa modulo2", enunciation: "Assignment para testar modulo", type_assignment: 0, schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
    params_course = {allocation_tags_ids: "#{allocation_tags(:al19).id}", assignment: {name: "Testa modulo3", enunciation: "Assignment para testar modulo", type_assignment: 0, schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}

    assert_no_difference(["Assignment.count", "Schedule.count", "AcademicAllocation.count"]) do
      post :create, params_offer
      post :create, params_uc
      post :create, params_course
    end

    assert_response :unprocessable_entity
  end

  test "edicao - deletar um trabalho" do
    assert_difference("Assignment.count", -1) do
      delete(:destroy, {id: assignments(:a4).id, allocation_tags_ids: [allocation_tags(:al3).id]})
    end
  end

  test "edicao - deletar varios trabalhos" do
    assignments = [2,4,6]
    assert_difference("Assignment.count", -assignments.count) do
      delete(:destroy, {id: assignments, allocation_tags_ids: [allocation_tags(:al3).id]})
    end
  end

end
