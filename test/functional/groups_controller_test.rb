require 'test_helper'

class GroupsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:aluno1)
  end

  ## API - Mobilis
  test "lista de turmas da disciplina de introducao a linguistica" do
    assert_routing '/curriculum_units/1/groups', {:controller => "groups", :action => "index", :curriculum_unit_id => "1"}

    get :index, {:format => 'json', :curriculum_unit_id => 1}
    assert_response :success
    assert_not_nil assigns(:groups)
  end

end
