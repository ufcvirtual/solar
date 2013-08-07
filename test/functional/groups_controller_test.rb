require 'test_helper'

class GroupsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  ## API - Mobilis
  test "lista de turmas da disciplina de introducao a linguistica" do
    sign_in users(:aluno1)
    assert_routing '/curriculum_units/1/groups', {controller:  "groups", action:  "index", curriculum_unit_id:  "1"}

    get :index, {format: 'json', curriculum_unit_id: 1}
    assert_response :success
    assert_not_nil assigns(:groups)
  end

  ##
  # Destroy
  ##

  # Usuário com permissão e acesso (remove seu respectivo módulo default, pois não possui aulas)
  test "remover turma" do 
    sign_in users(:editor)

    assert_difference(["Group.count", "LessonModule.count"], -1) do 
      get(:destroy, {id: groups(:g9).id, allocation_tags_ids: [allocation_tags(:al22).id]})
    end

    assert_response :success
  end

  # Usuário com permissão e acesso, mas a turma não permite (possui níveis inferiores)
  test "nao remove turma - niveis inferiores" do
    sign_in users(:editor)

    assert_no_difference(["Group.count", "LessonModule.count"]) do 
      get :destroy, {id: groups(:g3).id}
    end

    assert_response :unprocessable_entity
  end

end
