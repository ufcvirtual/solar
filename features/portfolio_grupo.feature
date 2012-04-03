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

#@wip
#Cenário: Exibir Detalhes de Trabalho de Grupo
        #Então eu deverei ver "Trabalhos em Grupo"
        #E eu deverei ver "Atividades Individuais"
        #E eu deverei ver "Descrição"
        #E eu deverei ver o link "Atividade III"
    #Quando eu clicar no link "Atividade III"