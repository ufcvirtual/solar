collection @users

@user.each do |user|
  attributes name: :name, email: :email
end
