# language: pt

Funcionalidade: Listar Provas
  Como um aluno do solar
  Eu quero visualizar as provas
  Para poder acessá-las

s@javascript
Cenário: Listar provas disponiveis
  Dado que estou logado com o usuario "aluno1" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "Quimica I" em "td.uc-name"
  Quando eu clicar no link "Prova"
    Então eu deverei ver "Provas disponíveis"
    E eu deverei ver "Prova 1"
    E eu deverei ver "Descrição da prova"
