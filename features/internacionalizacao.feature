#language: pt

Funcionalidade: Internacionalizacao
  Como um usuário do solar
  Eu quero escolher uma língua
  Para compreender o conteúdo do site

Cenário: Login EN
        Dado que estou em "Login"
                E eu deverei ver "Senha"
        Quando eu clicar no link "English"
        Então eu deverei ver "Password"

Cenário: Login ptBR
        Dado que estou em "Login"
                E eu deverei ver "Senha"
        Quando eu clicar no link "English"
        E eu clicar no link "Português(BR)"
        Então eu deverei ver "Senha"
        
