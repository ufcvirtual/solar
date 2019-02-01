object @user

attributes :id, :name, :email, :profile_name

node (:photo) { |user| "/api/v1/users/#{user.id}/photo" }