# language: pt

Funcionalidade: Portlet de unidades curriculares
  Como um usuário do solar
  Eu quero ver minha lista de unidades curriculares num portlet do home
  Para ter acesso rápido a suas páginas e atividades.

@javascript
Cenário: Acessar página do meuSolar e visualizar o Portlet de unidades curriculares
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
  Então eu deverei ver "Unidade Curricular"
    E eu deverei ver "RM404 - Introducao a Linguistica"
    E eu deverei ver "Quimica I"
    E eu nao deverei ver "Teoria da Literatura I"