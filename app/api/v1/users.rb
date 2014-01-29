module V1
  class Users < Base
    guard_all!

    namespace :users

    get :me, rabl: "user" do
      @user = current_user
    end

    # get ":id/photo" do
    #   {test: "test"}
    # end
  end
end
