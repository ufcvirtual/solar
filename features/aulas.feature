# language: pt
Funcionalidade: Exibir aulas de curso
  Como um usuario do solar
  Eu quero visualizar as aulas do curso
  Para poder acessá-las

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 1                  | 2           | 1      |
        | 2        | 1                  | 1           | 1      |
        | 3        | 1                  | 1           | 1      |

Cenário: Listar aulas do curso
    Dado que estou logado com o usuario "user" e com a senha "user123"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Introducao a Linguistica"
        Então eu deverei ver "Aulas"
    Quando eu clicar no link "Aulas"
    Então eu deverei ver "Aulas disponíveis"
    E eu deverei ver a linha de aulas disponiveis
      | AulasDisponiveis  | DataAcesso              |
      | aula 1 pag ufc    | 05/03/2011 - 20/06/2011 |
      | aula 2 pag uol    | 27/03/2011 - 27/06/2011 |

#@wip
#Cenário: Exibir aula do curso
#    Dado que estou logado com o usuario "user" e com a senha "user123"
#        E que estou em "Meu Solar"
#    Quando eu clicar em "Introducao a Linguistica"
#        Então eu deverei ver "Aulas"
#    Quando eu clicar no link "Aulas"
#        Então eu deverei ver o link "aula 1 pag ufc"
#    Quando eu clicar no link "aula 1 pag ufc"
#        Então eu deverei ver o link "1"
#        E eu deverei ver o link "2"
#        E eu deverei ver "Ir para aula"
