object @message 
attributes :id, :subject, :content

node(:sent_by) { |message| message.sent_by }
node(:recipients) { |message| message.recipients }
