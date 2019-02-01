collection @users

@users.each do |user|
  extends 'groups/participant', locals: { user: user }
end