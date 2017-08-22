object @message 
attributes :id, :subject, :content, :created_at, :updated_at

node(:sent_by) { { name: @message.sent_by.name, email: @message.sent_by.email, address: @message.sent_by.address } }
node :recipients do |msg|
  msg.recipients.map{|m| {name: m.name, email: m.email}}.each do |msg|
    [msg[:name], msg[:email]].join(' - ')
  end
end

child files: :files do |files|
  extends 'messages/files', locals: { files: files}
end
