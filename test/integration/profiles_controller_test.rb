require 'test_helper'

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 
  
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
