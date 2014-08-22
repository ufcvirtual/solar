# language: pt

Funcionalidade: Exibir participantes do curso
  Como um usuario do solar
  Eu quero visualizar os participantes do curso

Contexto:
Dado que tenho "allocations"
| user_id | allocation_tag_id | profile_id | status |
|    7    |         1         |     5      |    1   |
|    7    |         2         |     5      |    1   |
|    7    |         3         |     5      |    1   |

@javascript
Cenário: Visualizar participantes da turma
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "RM404 - Introducao a Linguistica" em "td.course"
    #E que eu selecionei "selected_group" com "IL-FOR - 2011.1"
    Então eu deverei ver "Participantes"
  E que eu espero 2 segundos
  Quando eu clicar no link "Participantes"
    Então eu deverei ver "Responsáveis"
    E eu deverei ver "Professor"
    E eu deverei ver "Usuario do Sistema"
    E eu deverei ver "Participantes da turma"
    E eu deverei ver "Aluno 1"
    E eu deverei ver "Aluno 2"
    E eu deverei ver "Aluno 3"
    E eu deverei ver "User 2"
    E eu deverei ver "User 3"
