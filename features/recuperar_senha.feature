#language: pt

Funcionalidade: Recuperar senha
  Como um usuário do solar
  Eu quero recuperar minha senha
  Para acessar os recursos do sistema

Cenário: Usuário acessa tela de recuperação de senha
  Dado que estou em "Login"
    E eu clico no link "Esqueceu a sua senha?"
  Então eu deverei ver "Esqueceu a sua senha?"
    E eu deverei ver o campo "email_password_recovery"
    E eu deverei ver o botao "Enviar"
