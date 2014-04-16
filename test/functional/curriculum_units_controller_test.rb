require 'test_helper'

class CurriculumUnitsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)
  end

  ## API - Mobilis
  test "lista de disciplinas em JSON" do
    sign_in users(:aluno1)
    assert_routing '/curriculum_units/list', {:controller => "curriculum_units", :action => "list"}

    get :list, {:format => 'json'}
    assert_response :success
    assert_not_nil assigns(:curriculum_units)
  end

  test "lista ucs" do
    get :index, {type_id: curriculum_unit_types(:distancia).id}
    assert_template :index
    assert_not_nil assigns(:curriculum_units)
  end

  test "nao lista ucs - sem permissao" do
    sign_in users(:aluno1)
    get :index, {type_id: curriculum_unit_types(:distancia).id}
    assert_response :redirect
    assert assigns(:curriculum_units).empty?
  end

  test "cria uc" do
    assert_difference("CurriculumUnit.count") do
      assert_no_difference("Course.count") do
        post :create, curriculum_unit: {curriculum_unit_type_id: curriculum_unit_types(:distancia).id, code: "C010", name: "Curso 10", resume: "Curso 10", syllabus: "Curso 10", objectives: "Curso 10"}
      end
    end

    assert_response :success
  end

  test "cria uc - curso livre" do
    assert_difference(["CurriculumUnit.count", "Course.count"]) do
      post :create, curriculum_unit: {curriculum_unit_type_id: curriculum_unit_types(:livre).id, code: "C010", name: "Curso 10", resume: "Curso 10", syllabus: "Curso 10", objectives: "Curso 10"}
    end

    assert_response :success
  end

  test "nao cria uc - sem permissao" do
    sign_in users(:aluno1)
    assert_no_difference("CurriculumUnit.count") do
      post :create, curriculum_unit: {curriculum_unit_type_id: curriculum_unit_types(:distancia).id, code: "C010", name: "Curso 10", resume: "Curso 10", syllabus: "Curso 10", objectives: "Curso 10"}
    end

    assert_response :redirect
  end

  test "editar uc" do
    quimica = curriculum_units(:r3)
    assert_no_difference("CurriculumUnit.count") do
      put :update, {id: quimica.id, curriculum_unit: {code: "AAAA"}}
    end
    assert_equal "AAAA", CurriculumUnit.find(quimica.id).code
  end

  test "editar uc - curso livre" do
    post :create, curriculum_unit: {curriculum_unit_type_id: curriculum_unit_types(:livre).id, code: "C010", name: "Curso 10", resume: "Curso 10", syllabus: "Curso 10", objectives: "Curso 10"}
    new_curriculum_unit, new_course = CurriculumUnit.find_by_code("C010"), Course.find_by_code("C010")
    assert_no_difference(["CurriculumUnit.count", "Course.count"]) do
      put :update, {id: new_curriculum_unit.id, curriculum_unit: {code: "AAAA"}}
    end
    assert_equal "AAAA", CurriculumUnit.find(new_curriculum_unit.id).code
    assert_equal "AAAA", Course.find(new_course.id).code
  end

  test "nao editar uc - sem permissao" do
    sign_in users(:aluno1)
    rm405 = curriculum_units(:r2)
    assert_no_difference("CurriculumUnit.count") do
      put :update, {id: rm405.id, curriculum_unit: {code: "AAAA", curriculum_unit_type_id: rm405.curriculum_unit_type_id, code: rm405.code, name: rm405.name, resume: rm405.resume, syllabus: rm405.syllabus, objectives: rm405.objectives}}
    end
    assert_not_equal "AAAA", CurriculumUnit.find(rm405.id).code
  end

  test "remover uc" do
    post :create, curriculum_unit: {curriculum_unit_type_id: curriculum_unit_types(:distancia).id, code: "C010", name: "Curso 10", resume: "Curso 10", syllabus: "Curso 10", objectives: "Curso 10"}
    new_curriculum_unit = CurriculumUnit.find_by_code("C010")
    assert_difference("CurriculumUnit.count", -1) do
      delete :destroy, {id: new_curriculum_unit.id}
    end
    assert_response :success
  end

  test "remover uc - curso livre" do
    post :create, curriculum_unit: {curriculum_unit_type_id: curriculum_unit_types(:livre).id, code: "C010", name: "Curso 10", resume: "Curso 10", syllabus: "Curso 10", objectives: "Curso 10"}
    new_curriculum_unit = CurriculumUnit.find_by_code("C010")
    assert_difference(["CurriculumUnit.count", "Course.count"], -1) do
      delete :destroy, {id: new_curriculum_unit.id}
    end
    assert_response :success
  end

  test "nao remover uc - sem permissao" do
    sign_in users(:professor)

    quimica_organica = curriculum_units(:r6)
    assert_no_difference("CurriculumUnit.count") do
      delete :destroy, {id: quimica_organica.id}
    end
    assert_response :redirect
  end

  test "nao remover uc - dependencias" do
    rm301 = curriculum_units(:r3)
    assert_no_difference("CurriculumUnit.count") do
      delete :destroy, {id: rm301.id}
    end
    assert_response :unprocessable_entity
  end

end
