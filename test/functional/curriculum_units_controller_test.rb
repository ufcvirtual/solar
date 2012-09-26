require 'test_helper'

class CurriculumUnitsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:aluno1)
  end

  ## API - Mobilis
  test "lista de disciplinas em JSON" do
    assert_routing '/curriculum_units/list', {:controller => "curriculum_units", :action => "list"}

    get :list, {:format => 'json'}
    assert_response :success
    assert_not_nil assigns(:curriculum_units)
  end

end
