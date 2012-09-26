require 'test_helper'

class DiscussionsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:aluno1)
  end

  ## API - Mobilis
  test "lista de foruns da turma FOR de introducao a liguistica" do
    assert_routing '/groups/1/discussions', {:controller => "discussions", :action => "index", :group_id => "1"}

    get :index, {:format => 'json', :group_id => 1}
    assert_response :success
    assert_not_nil assigns(:discussions)
  end

end
