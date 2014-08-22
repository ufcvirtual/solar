# language: pt

Funcionalidade: Exibir aulas de curso
  Como um usuario do solar
  Eu quero visualizar as aulas do curso
  Para poder acessá-las

@javascript
Cenário: Listar aulas do curso
  Dado que estou logado com o usuario "aluno1" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "109 - Licenciatura em Quimica" em "td.course"
    Então eu deverei ver "Aulas"
    Então eu deverei ver "Material de Apoio"        
  Quando eu clicar no link "Aulas"
  Então eu deverei ver "Aulas disponíveis"
  E eu deverei ver a linha de aulas disponiveis
    | AulasDisponiveis     | DataAcesso | DataAcesso | DataAcesso |
    | aula 5               | 25/03/2011 |      -     | 06/05/2022 |
