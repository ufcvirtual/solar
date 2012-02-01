# language: pt
Funcionalidade: Exibir participantes do curso
  Como um usuario do solar
  Eu quero visualizar os participantes do curso

Contexto:
Dado que tenho "allocations"
| user_id | allocation_tag_id | profile_id | status |
|    1    |         3         |     1      |    1   |
|    1    |         1         |     1      |    1   |
|    1    |         9         |     1      |    1   |
|    7    |         1         |     5      |    1   |
|    7    |         2         |     5      |    1   |
|    7    |         3         |     5      |    1   |

  @javascript
  Cenário: Visulizar participantes da turma
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Introducao a Linguistica"
        E que eu selecionei "selected_group" com "FOR - 2011.1"
        E eu clicar no link "Informações Gerais"
    Então eu deverei ver "Participantes"
    Quando eu clicar no link "Participantes"
        Então eu deverei ver "Responsáveis"
        E eu deverei ver "Usuario do Sistema"
        E eu deverei ver "Participantes da turma"
        E eu deverei ver "Ricardo Palacio"
        E eu deverei ver "Bezerra"
