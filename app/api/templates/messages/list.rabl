object false

node(:total) { @total }
node(:pages_amount) { @pages_amount }

child @messages => :messages do
  @messages.each do |message|
    extends 'messages/show', locals: {message: message}
  end
end

