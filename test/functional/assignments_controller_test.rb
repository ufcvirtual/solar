require 'test_helper'

class AssignmentsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  fixtures :allocation_tags, :assignments, :group_assignments, :users, :sent_assignments

  def setup
    sign_in users(:editor)
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
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end
  

  # ######## TESTE PARA VALIDAR O MÓDULO: ASSIGNMENT SÓ PODE EM TURMA, NÃO PODE EM OFERTA, NEM UC, NEM CURSO #########
  # ##            quando o cadastro de assignment for concluído, favor descomentar o teste abaixo                   ##
  # ##  tem que conferir se o cadastro realmente está sendo feito assim ou é de modo diferente se o modo como as    ##
  # ##  allocation_tags são passadas for diferente, o importante é criar a turma nos dados colocados                ##
  #
  # test "nao cria trabalho para oferta ou curso ou uc - modulo permite apenas turma" do
  #   params_offer  = allocation_tags_ids: [allocation_tags(:al6).id], assignment: {name: "Testa módulo1", enunciation: "Assignment para testar módulo", type_assignment: 0, schedule: {start_date: Date.today, end_date: Date.today + 1.month}}
  #   params_uc     = allocation_tags_ids: [allocation_tags(:al13).id], assignment: {name: "Testa módulo2", enunciation: "Assignment para testar módulo", type_assignment: 0, schedule: {start_date: Date.today, end_date: Date.today + 1.month}}
  #   params_course = allocation_tags_ids: [allocation_tags(:al19).id], assignment: {name: "Testa módulo3", enunciation: "Assignment para testar módulo", type_assignment: 0, schedule: {start_date: Date.today, end_date: Date.today + 1.month}}

  #   assert_no_difference(["Assignment.count", "Schedule.count"]) do
  #     post :create, params_offer
  #     post :create, params_uc
  #     post :create, params_course
  #   end
  #
  #   assert_response :unprocessable_entity
  # end

  ##
  # Edicao
  ##
=begin # Testes ou funcionalidades serão refeitos
  test "listar trabalhos para edicao" do
    sign_in users(:editor)
    get :list, {what_was_selected: %(false false false true), allocation_tags_ids: [allocation_tags(:al3).id]}
    assert_response :success
    assert_not_nil assigns(:allocation_tags_ids)
    assert_not_nil assigns(:assignments)
  end

  test "criar trabalho individual para uma unica turma" do
    sign_in users(:editor)

    assert_difference("Assignment.count", 1) do
      assignment = {
        allocation_tags_ids: "#{allocation_tags(:al3).id}",
        assignment: {
          schedule_attributes: {
            start_date: Time.now.to_date.to_s,
            end_date: (Time.now + 2.months).to_date.to_s,
          },
          allocation_tag_id: [allocation_tags(:al3).group.id],
          name: 'trabalho 1',
          enunciation: 'enunciado do trabalho 1',
          type_assignment: Assignment_Type_Individual,
          end_evaluation_date: (Time.now + 3.months).to_date.to_s
        }
      }
      post(:create, assignment)
    end
    assert_response :success
  end

  test "criar trabalho em grupo para duas turmas" do
    sign_in users(:editor)

    allocation_tags_ids = [allocation_tags(:al3).id, allocation_tags(:al11).id]
    get :new, {allocation_tags_ids: allocation_tags_ids}
    assert_template :new

    assert_difference("Assignment.count", 2) do
      assignment = {
        allocation_tags_ids: allocation_tags_ids.join(" "),
        assignment: {
          schedule_attributes: {
            start_date: Time.now.to_date.to_s,
            end_date: (Time.now + 2.months).to_date.to_s,
          },
          allocation_tag_id: [allocation_tags(:al3).group.id, allocation_tags(:al11).group.id], # turmas de quimica
          name: 'trabalho 1',
          enunciation: 'enunciado do trabalho 1',
          type_assignment: Assignment_Type_Group,
          end_evaluation_date: (Time.now + 3.months).to_date.to_s
        }
      }
      post(:create, assignment)
    end
    assert_response :success
  end

  test "editar trabalho" do
    sign_in users(:editor)

    # atividade II de  quimica I
    get :edit, {id: assignments(:a2).id, allocation_tags_ids: [allocation_tags(:al3).id]}
    assert_template :edit
    assert_not_nil assigns(:assignment)
  end

  test "atualizar trabalho" do
    sign_in users(:editor)

    assert_equal "Atividade II", assignments(:a2).name
    assert_no_difference("Assignment.count") do
      put :update, {id: assignments(:a2).id, assignment: {name: "Trabalho II"}, allocation_tags_ids: [allocation_tags(:al3).id]}
    end
    assert_response :success
    assert_equal "Trabalho II", Assignment.find(assignments(:a2).id).name
  end

  test "deletar apenas um trabalho" do
    sign_in users(:editor)

    assert_difference("Assignment.count", -1) do
      delete(:destroy, {id: assignments(:a4).id, allocation_tags_ids: [allocation_tags(:al3).id]})
    end
  end

  test "deletar varios trabalhos" do
    sign_in users(:editor)
    assignments = allocation_tags(:al3).group.assignments.includes(:sent_assignments).where(sent_assignments: {id: nil})
    assert_difference("Assignment.count", -assignments.count) do
      delete(:destroy, {id: assignments.map(&:id), allocation_tags_ids: [allocation_tags(:al3).id]})
    end
  end
=end
end
