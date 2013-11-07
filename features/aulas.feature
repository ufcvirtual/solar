# language: pt

Funcionalidade: Exibir aulas de curso
  Como um usuario do solar
  Eu quero visualizar as aulas do curso
  Para poder acessá-las

@javascript
Cenário: Listar aulas do curso
  Dado que estou logado com o usuario "aluno1" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "Quimica I"
    Então eu deverei ver "Aulas"
  Quando eu clicar no link "Conteúdo"
    Então eu deverei ver "Material de Apoio"        
  Quando eu clicar no link "Aulas"
  Então eu deverei ver "Aulas disponíveis"
  E eu deverei ver a linha de aulas disponiveis
    | AulasDisponiveis  | DataAcesso | DataAcesso | DataAcesso |
    | aula 4            | 16/03/2011 |      -     | 01/08/2312 |
    | aula 5            | 25/03/2011 |      -     | 06/05/2315 |
