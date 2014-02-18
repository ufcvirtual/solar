ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  set_fixture_class discussion_posts: Post
  fixtures :all

  def get_json_response(param)
    return JSON.parse(@response.body)[param]
  end
end
