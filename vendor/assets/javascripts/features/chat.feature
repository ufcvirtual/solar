# language: pt

Funcionalidade: Exibir Chats
  Como um usuario do solar
  Eu quero visualizar os chats
  Para poder acessá-los

Cenário: Acessar listagem de chat
  Dado que estou logado com o usuario "aluno1" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "Quimica I"
    Então eu deverei ver "Atividades"
  Quando eu clicar no link "Atividades"
    Então eu deverei ver o link "Chat"
  Quando eu clicar no link "Chat"
    Então eu deverei ver os meus chats
    | Chat            | Data                     | Hora          |
    | Chat 02         | 01/12/2011 - 01/12/2014  |  9:00 - 10:40 |
    | Chat 01         | 01/12/2011 - 01/12/2014  | 10:00 - 18:40 |
    | Chat 03         | 01/12/2011 - 01/12/2014  | 10:00 - 14:00 |
