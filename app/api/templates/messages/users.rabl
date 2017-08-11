collection @users

@user.each do |user|
  attributes: name: :message.sent_by,  
end
