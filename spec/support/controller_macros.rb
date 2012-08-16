module ControllerMacros
  def login_user(fixture_user)
    fixtures :users

    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user = users(fixture_user)
      sign_in user
    end
  end
end
