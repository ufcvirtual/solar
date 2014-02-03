module V1
  class Users < Base
    guard_all!

    namespace :users

    get :me, rabl: "users/show" do
      @user = current_user
    end
  end
end
