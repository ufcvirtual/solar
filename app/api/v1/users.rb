module V1
  class Users < Base
    namespace :users

    guard_all!

    get :me, rabl: "user" do
      @user = current_user
    end

    # get ":id/photo" do
    #   {test: "test"}
    # end
  end
end
