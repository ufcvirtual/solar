module V1
  class Users < Base
    guard_all!

    namespace :users

    # GET /users/me
    get :me, rabl: "users/show" do
      @user = current_user
    end

    # GET /users/1/photo
    get "/:id/photo" do
      begin
        user = User.find(params[:id])
        photo = user.photo.path(params[:style] || :small)
        filename = Digest::MD5.hexdigest(user.cpf)

        content_type MIME::Types.type_for(filename)[0].to_s
        env['api.format'] = :binary
        header "Content-Disposition", "attachment; filename*=UTF-8''#{URI.escape(filename)}"

        File.open(photo).read
      rescue
        raise ActiveRecord::RecordNotFound
      end
    end

  end
end
