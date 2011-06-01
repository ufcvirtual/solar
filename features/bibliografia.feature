# language: pt
Funcionalidade: Exibir biliografias da oferta
  Como um usuario do solar
  Eu quero visualizar as bibliografias da oferta
  Para poder acessá-las

Cenário: Exibir bibliografia
    Dado que estou logado com o usuario "user" e com a senha "user123"
        E que estou em "Meu Solar"
    Quando eu clicar em "Quimica I"
        Então eu deverei ver "Informacoes Gerais"
    Quando eu clicar no link "Informacoes Gerais"
        Então eu deverei ver o link "Bibliografia"
    Quando eu clicar no link "Bibliografia"
        Então eu deverei ver "Bibliografia"
        E eu deverei ver "Rafael Patao"
        E eu deverei ver "Sistemas embarcados em aviões e em barcos "
        E eu deverei ver "eu"