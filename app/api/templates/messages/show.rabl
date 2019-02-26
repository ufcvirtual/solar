object @message
attributes :id, :subject, :content, :created_at, :updated_at

node(:sent_by) { { name: @message.sent_by.name, email: @message.sent_by.email, id: @message.sent_by.id } }

if @message.respond_to?(:wasnt_read)
  node(:read) {|msg| msg.wasnt_read == 0}
end

node :recipients do |msg|
  msg.recipients.map{|m| {name: m.name, email: m.email}}.each do |msg|
    [msg[:name], msg[:email]].join(' - ')
  end
end

child files: :files do |files|
  # files = MessageFile.where(message_id: msg.id)
  extends 'messages/files', locals: {files: files}
end
