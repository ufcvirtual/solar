# language: pt
Funcionalidade: Exibir Página de Grupos de Portfolio
  Como um usuário do solar
  Eu quero listar os trabalhos de grupo disponíveis
  Para poder gerenciar os grupos de trabalho

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 3                  | 3           | 1      |

Cenário: Exibir Tela de Cadastro de Trabalho de Grupo
    Dado que estou logado com o usuario "prof" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Grupos"
    Quando eu clicar no link "Grupos"
        Então eu deverei ver o link "Atividade em grupo I"
        Então eu deverei ver o link "Atividade em grupo II"

@wip
@javascript
Cenário: Exibir Grupos de Trabalho
    Dado que estou logado com o usuario "prof" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Grupos"
    Quando eu clicar no link "Grupos"
        Então eu deverei ver o link "Atividade em grupo I"
        Então eu deverei ver o link "Atividade em grupo II"
    Quando eu clicar no link "Atividade em grupo I"
        Então eu deverei ver "grupo1 tI"
        E eu deverei ver "grupo2 tI"
        E eu deverei ver "grupo3 tI"
    Quando eu clicar no link "Atividade em grupo II"
        Então eu deverei ver "grupo1 - tII"
        E eu deverei ver "grupo2 - tII"
