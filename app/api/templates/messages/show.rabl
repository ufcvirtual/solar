object @message 
attributes :id, :subject, :content

#node(:sent_by) { |message| message.sent_by }
#node(:recipients) { |message| message.recipients, type: Array[Integer, String]}

# node :sent_by do |message|
#   extends 'messages/users', locals: { users: message.sent_by}
# end

# node :recipients do |message|
#   extends 'messages/users', locals: { users: message.recipients}
# end

child files: :files do |files|
  extends 'messages/files', locals: { files: files}
end
