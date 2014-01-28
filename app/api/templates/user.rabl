object @user

attributes :name, :username, :email

node :photo do
  "/users/#{@user.id}/photo"
end
