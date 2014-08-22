# language: pt

Funcionalidade: Exibir biliografias da oferta
  Como um usuario do solar
  Eu quero visualizar as bibliografias da oferta
  Para poder acessá-las

@javascript
Cenário: Exibir bibliografia
  Dado que estou logado com o usuario "aluno1" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "109 - Licenciatura em Quimica" em "td.course"
    Então eu deverei ver "Bibliografia"
  Quando eu clicar no link "Bibliografia"
    Então eu deverei ver "Itens Bibliográficos"
    Então eu deverei ver "Item"
    E eu deverei ver "LOREM, Ipsum, DOLOR, Sit Amet. Lorem ipsum dolor sit amet, consectetur adipiscing elit. 1. ed. Lorem ipsum dolor sit amet, consectetur adipiscing elit: Lorem ipsum, 2011. 350 p"
    Então eu deverei ver "Tipo"
    E eu deverei ver "Livro"
