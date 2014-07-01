object @user

attributes :id, :name, :username, :email

node (:photo) { "/api/v1/users/#{@user.id}/photo" }
