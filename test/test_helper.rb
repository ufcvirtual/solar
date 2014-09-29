ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 
  # para reconhecer o método "fixture_file_upload" no teste de integração
  include ActionDispatch::TestProcess

  set_fixture_class discussion_posts: Post
  fixtures :all

  def get_json_response(param)
    return JSON.parse(@response.body)[param]
  end

  def login(user)
    login_as user, scope: :user
  end

end
