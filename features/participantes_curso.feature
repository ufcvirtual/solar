# language: pt
Funcionalidade: Exibir participantes do curso
  Como um usuario do solar
  Eu quero visualizar os participantes do curso

Contexto:
    Dado que tenho "allocations"
        | users_id | allocation_tags_id | profiles_id | status |
        | 1        | 4                  | 2           | 1      |
        | 2        | 4                  | 1           | 1      |
        | 3        | 4                  | 1           | 1      |

Cenário: Acessar pagina de informacoes do curso
    Dado que estou logado com o usuario "user" e com a senha "user123"
        E que estou em "Meu Solar"
        Quando eu clicar em "Introducao a Linguistica"
    Então eu deverei ver "Participantes"
        Quando eu clicar no link "Participantes"
    Então eu deverei ver "Responsáveis"
        E eu deverei ver "Usuario do Sistema"
        E eu deverei ver "Participantes da turma"
        E eu deverei ver "Ricardo Palacio"
        E eu deverei ver "Bezerra"