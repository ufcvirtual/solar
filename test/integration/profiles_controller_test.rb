require 'test_helper'

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  
  def setup
    login(users(:admin))
    get home_path
  end

  test "listagem de perfis" do
    get profiles_path

    assert_response :success
    assert_not_nil assigns(:all_profiles)
  end

end
