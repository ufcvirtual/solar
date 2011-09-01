# Inicializando uma nova validacao
require File.join(::Rails.root.to_s, 'lib', 'validations', 'blacklist')

#mudando armazenamento de sessao para o banco
Solar::Application.config.black_list = [
  'application/x-asp',
  'application/octet-stream', # exe, aspx, jsp, bat
  'application/x-php',
  'text/x-java',
  'application/x-java' # class
]
