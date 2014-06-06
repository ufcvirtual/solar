#language: pt

Funcionalidade: Acessar e alterar dados pessoais
  Como um usuário do solar
  Eu quero editar meus dados
  Para atualizar as minhas informações no sistema

Cenário: Acessar página de Edição de Dados Pessoais
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meus Dados"
  Então eu deverei ver "Nome"
    E eu deverei ver "Bio"
    E eu deverei ver "Interesses"
    E eu deverei ver "Música"
    E eu deverei ver "Filmes"
    E eu deverei ver "Livros"
    E eu deverei ver "Frase"
    E eu deverei ver "Site"


Cenário: Acessar página de Edição de Dados Cadastrais
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meus Dados"
  Então eu deverei ver "Nome"
    E eu deverei ver "Apelido"
    E eu deverei ver "Data de Nascimento"
    E eu deverei ver "Sexo"
    E eu deverei ver "CPF"
    E eu deverei ver "Contato"
    E eu deverei ver "E-mail"
    E eu deverei ver "E-mail alternativo"
    E eu deverei ver "Telefone"
    E eu deverei ver "Instituição"
    E eu deverei ver "Endereço"
    E eu deverei ver "Número"
    E eu deverei ver "Cidade"
    E eu deverei ver "CEP"
    E eu deverei ver "Estado"
    E eu deverei ver "Bairro"
    E eu deverei ver "País"
    E eu deverei ver "Acesso"
    E eu deverei ver "Login"
    E eu deverei ver "Senha"
    E eu deverei ver "Necessidades especiais"

Cenário: Alterar dados Pessoais
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meus Dados"
    E que eu preenchi "user_bio" com "Bicampeao Estadual em 94 e 95"
    E que eu preenchi "Interesses" com "Leitura e paz mundial"
    E que eu preenchi "Música" com "MPB forró reaggue e Restart"
    E que eu preenchi "Filmes" com "The Fighters 2010"
    E que eu preenchi "Livros" com "The Hobbit"
    E que eu preenchi "Frase" com "Bazzinga"
    E que eu preenchi "Site" com "www.kibeloco.com.br"
    E que eu preenchi "user_current_password" com "123456"
  Quando eu clicar em "confirm"
  Então eu deverei ver "Dados atualizados com sucesso."


Cenário: Alterar dados Cadastrais
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meus Dados"
    E que eu preenchi "name" com "Usuário do Solar"
    E que eu preenchi "nick" com "usuario"
    E que eu selecionei a data "13/12/2001" no campo com id "user_birthdate"
    E que eu selecionei "user_gender" com "M"
    E que eu preenchi "cpf" com "72416475304"
    E que eu preenchi "email" com "usuario@solar.virtual.ufc.br"
    E que eu preenchi "email_confirmation" com "usuario@solar.virtual.ufc.br"
    E que eu preenchi "user_alternate_email" com "alexiei@solar.virtual.ufc.br"
    E que eu preenchi "telephone" com "8533222233"
    E que eu preenchi "institution" com "Elzir Cabral"
    E que eu preenchi "address" com "Rua Sei Não"
    E que eu preenchi "address_number" com "123"
    E que eu preenchi "zipcode" com "60000000"
    E que eu preenchi "address_neighborhood" com "Sei la qual"
    E que eu preenchi "city" com "Fortaleza"
    E que eu selecionei "user_state" com "CE"
    E que eu preenchi "country" com "Brasil"
    E que eu preenchi "username" com "usuario"
    E que eu preenchi "user_current_password" com "123456"
    E que eu preenchi "user_password" com "12345678"
    E que eu preenchi "user_password_confirmation" com "12345678"
  Quando eu clicar em "confirm"
  Então eu deverei ver "Dados atualizados com sucesso."


Esquema do Cenário: Alteração de senha
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meus Dados"
    E que eu preenchi "user_current_password" com "<antiga_senha>"
    E que eu preenchi "user_password" com "<nova_senha>"
    E que eu preenchi "user_password_confirmation" com "<confirmar_senha>"
  Quando eu clicar em "confirm"
  Então eu deverei ver "<action>"

Exemplos:
  | antiga_senha         |  nova_senha       |  confirmar_senha      | action                                        |
  | xyz                  |                   |                       | Senha não é válido(a)                         |
  | xyz                  |  user456          |  user456              | Senha não é válido(a)                         |
  | 123456               |  user456          |  user789              | Senha não está de acordo com a confirmação    |
  |                      |  user456          |  user456              | Senha obrigatório                  |
  |                      |  user456          |  user789              | Senha obrigatório                  |
  | 123456               |                   |  user789              | Senha não está de acordo com a confirmação    |
  | 123456               |  user789          |                       | Senha não está de acordo com a confirmação    |
  | xyz                  |                   |  user789              | Senha não é válido(a)                         |
  | xyz                  |  user789          |                       | Senha não é válido(a)                         |
  |                      |                   |  user789              | Senha obrigatório                  |
  |                      |  user789          |                       | Senha obrigatório                  |
  | 123456               |  user789          |  user789              | Dados atualizados com sucesso.                |

@javascript
Cenário:  Acessar Edição de foto
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "mysolar_top_user_nick"
  Então eu deverei ver "Alterar foto"
  E eu clicar no link "change_picture"
  Então eu deverei ver o botao "Enviar"


#Esquema do Cenário: Enviar foto
#    Dado que estou logado com o usuario "user" e com a senha "123456"
#       E que estou em "Meu Solar"
#    Quando eu clicar no link "mysolar_top_user_nick"
#    E eu clicar no link "mysolar_change_picture"
#    E eu envio o arquivo "<foto>" no campo "user_photo"
#    Quando eu clicar em "Enviar"
#    Então eu deverei ver "<saida>"
#Exemplos:
#    | foto                                                    | saida                                                                               |
#    | images/photo_valid.png                                  | Foto alterada com sucesso!                                                          |
#    | images/photo_valid_no_extension                         | Foto alterada com sucesso!                                                          |
#    | images/photo_invalid_type.txt                           | Tipo de arquivo inválido. Por favor, envie apenas arquivos do tipo JPG, GIF ou PNG. |
#    | images/photo_invalid_type_size_and_valid_extension.png  | Arquivo muito grande. O tamanho máximo da sua foto deve ser de até 700KB.           |
#    | images/photo_invalid_size.png                           | Arquivo muito grande. O tamanho máximo da sua foto deve ser de até 700KB.           |
#    | images/photo_invalid_type_and_valid_extension.png       | Tipo de arquivo inválido. Por favor, envie apenas arquivos do tipo JPG, GIF ou PNG. |
#    | images/photo_invalid_no_extension                       | Tipo de arquivo inválido. Por favor, envie apenas arquivos do tipo JPG, GIF ou PNG. |
