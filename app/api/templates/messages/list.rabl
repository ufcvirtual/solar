collection @messages

@messages.each do |message|
  extends 'messages/show', locals: {message: message}
end 
