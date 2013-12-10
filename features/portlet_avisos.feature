# language: pt

Funcionalidade: Portlet de avisos
  Como um usuário do solar
  Eu quero ver minha lista de avisos do sistema

@javascript
Cenário: Acessar página do meuSolar e visualizar o Portlet de avisos
  Dado que estou logado com o usuario "aluno1" e com a senha "123456"
    E que estou em "Meu Solar"
  Então eu deverei ver "Avisos"
    E eu deverei ver "Lorem ipsum dolor sit amet"
    E eu deverei ver "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
