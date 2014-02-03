object @user

attributes :id, :name, :username, :email

node :photo do
  photo_user_url(@user.id)
end
