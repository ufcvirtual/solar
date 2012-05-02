# language: pt
Funcionalidade: Exibir Agenda da oferta
  Como um usuario do solar
  Eu quero visualizar a agenda da oferta
  Para poder acessá-las

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 3                  | 1           | 1      |
        | 5        | 4                  | 2           | 1      |
        | 5        | 5                  | 2           | 1      |
        | 5        | 6                  | 2           | 1      |

Cenário: Exibir Agenda
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Informações Gerais"
    Quando eu clicar no link "Informações Gerais"
        Então eu deverei ver o link "Agenda"
    Quando eu clicar no link "Agenda"
        Então eu deverei ver "Recesso"
        E eu deverei ver "Reunião com videoconferência"
        E eu deverei ver "Avaliação"
        E eu deverei ver "Feriado"

Cenário: Exibir Agenda do professor
    Dado que estou logado com o usuario "prof2" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Teoria da Literatura I"
        Então eu deverei ver "Informações Gerais"
    Quando eu clicar no link "Informações Gerais"
        Então eu deverei ver o link "Agenda"
    Quando eu clicar no link "Agenda"
        Então eu deverei ver "Trabalho"
        E eu deverei ver "13/Ago - 17/Set"
        E eu deverei ver "Atividade I"

#@wip
#Cenário: Exibir agenda do portlet
#     Dado que estou logado com o usuario "user" e com a senha "123456"
#        E que estou em "Meu Solar"
#    Quando eu clicar em "Quimica I"
#         Então eu deverei ver "Agenda"
#    Quando eu clicar em "23"
#         Então eu deverei ver "Atividade 4"
#    Quando eu clicar em "24"
#         Então eu deverei ver "Sem eventos para o dia selecionado"
