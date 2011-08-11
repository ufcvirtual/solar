class MessageFile < ActiveRecord::Base
  belongs_to :message

  # Configuração do paperclip para upload de arquivos
  has_attached_file :message,
    :path => ":rails_root/media/message/:id_:basename.:extension",
    :url => "/media/message/:id_:basename.:extension"

  validates_attachment_size :message, :less_than => 10.megabytes, :message => " " # Esse :message => " " deve permanecer dessa forma enquanto não descobrirmos como passar a mensagem de forma correta. Se o message for vazio a validação não é feita.

end
