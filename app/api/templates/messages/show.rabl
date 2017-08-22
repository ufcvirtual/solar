object @message 
attributes :id, :subject, :content, :created_at, :updated_at

# node(:sent_by) { |message| message.sent_by.address }
# node(:recipients) { |message| message.recipients }

node :sent_by do |message|
  # extends 'messages/users', locals: { users: message.sent_by }
  message.sent_by.name
end

# node :recipients do |user_message|
#   extends 'messages/users', locals: { users: user_message}
# end

child files: :files do |files|
  extends 'messages/files', locals: { files: files}
end
