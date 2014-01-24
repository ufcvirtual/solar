module V1
  class Users < Base
    namespace :users

    guard_all!

    get :me, rabl: "user" do
      @user = current_user
    end
  end
end
