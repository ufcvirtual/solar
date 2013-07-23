class MessageFile < ActiveRecord::Base
  belongs_to :original_message, class_name: "Message", foreign_key: "message_id"

  # Configuração do paperclip para upload de arquivos
  has_attached_file :message,
    :path => ":rails_root/media/messages/:id_:filename",
    :url => "/media/messages/:id_:filename"

  validates_attachment_size :message, :less_than => 10.megabytes, :message => " " # Esse :message => " " deve permanecer dessa forma enquanto não descobrirmos como passar a mensagem de forma correta. Se o message for vazio a validação não é feita.

  validates_attachment_content_type_in_black_list :message
end
