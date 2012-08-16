#language: pt

Funcionalidade: Enviar, receber e visualizar mensagens
  Como um usuário do solar
  Eu quero enviar, receber e visualizar mensagens
  Para me comunicar com os demais usuários do sistema

Contexto:
#    Dado que tenho "courses"
#        | id | name                    | code   |
#        | 1  | Letras Português        | LLPT   |
#        | 2  | Licenciatura em Química | LQUIM  |
Dado que tenho "allocations"
  | user_id  | allocation_tag_id  | profile_id  | status |
  | 1        | 1                  | 1           | 1      |
  | 1        | 2                  | 1           | 1      |
  | 1        | 3                  | 1           | 1      |
  | 1        | 8                  | 1           | 0      |
  | 1        | 8                  | 1           | 1      |
  | 5        | 4                  | 2           | 1      |
  | 5        | 5                  | 2           | 1      |
  | 5        | 6                  | 2           | 1      |

Cenário: Abrir mensagem
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
    E eu clicar no link "Mensagens"
  Quando eu clicar no link "professor2"
  Então eu deverei ver o link "Nova Mensagem"
    E eu deverei ver "Excluir"
    E eu deverei ver "Marcar como não lida"
    E eu deverei ver "<prof2@prof2.br>"
    E eu deverei ver "<user@user.com>"
    E eu deverei ver "assunto da msg 27/5 (ii)"
    E eu deverei ver "bla bla bla ..." 
    E eu deverei ver o link "Responder"
    E eu deverei ver o link "Responder para todos"
    E eu deverei ver o link "Encaminhar"

Cenário: Acessar página de mensagens a partir de "Unidade curricular"
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "Teoria da Literatura I"
  Entao eu deverei ver a migalha de pao "Home" > "Teoria da Literatura I"
    E eu clicar no link "Mensagens"
    E eu deverei ver "professor2"
    E eu deverei ver "assunto da msg 1"
    E eu deverei ver "11/05 10:42 h"
    E eu nao deverei ver "assunto da msg 27/5 (ii)"
    E eu nao deverei ver "27/05 16:42 h"

#@wip
#Cenário: Acessar página de mensagens a partir do "Meu Solar"
#   Dado que estou logado com o usuario "user" e com a senha "123456"
#   E que estou em "Meu Solar"
#   Quando eu clicar no link "Mensagens"
#   Entao eu deverei ver a migalha de pao "Home" > "Mensagens"
#       E eu deverei ver "Mensagens"
#       E eu deverei ver "Buscar Mensagem"
#       E eu deverei ver o link "Entrada"
#       E eu deverei ver o link "Enviadas"
#       E eu deverei ver o link "Lixeira"
#       E eu deverei ver o link "Nova Mensagem"
#       E eu deverei ver o link "Selecionar"
#       E eu deverei ver o link "Mover para"
#       E eu deverei ver "Excluir"
#       E eu deverei ver "Marcar como lida"
#       E eu deverei ver "Marcar como não lida"
#       E eu deverei ver a linha de mensagem
#       | coluna1    | coluna2                     | coluna3       |
#       | professor2 | assunto da msg 27/5 (i)     | 27/05 13:42 h |
#       | professor2 | assunto da msg 27/5 (ii)    | 27/05 16:42 h |


#Cenário: Criar e enviar mensagem
#Cenário: Encaminhar mensagem
#Cenário: Responder mensagem
#Cenário: Buscar mensagem
#Cenário: Excluir mensagem
#Cenário: Excluir da Lixeira
#Cenário: Mover mensagem
#Cenário: Marcar mensagem como lida
#Cenário: Marcar mensagem como não lida
