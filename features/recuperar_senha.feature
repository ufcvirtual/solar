#language: pt

Funcionalidade: Recuperar senha
  Como um usuário do solar
  Eu quero recuperar minha senha
  Para acessar os recursos do sistema

#@wip
Cenário: Usuário acessa tela de recuperação de senha
	Dado que estou em "Login"
		E eu clico no link "Esqueci minha senha"
	Então eu deverei ver "Esqueceu a sua senha?"
		E eu deverei ver "CPF"
		E eu deverei ver "E-mail"
		E eu deverei ver o botao "Enviar"

#Cenário: Usuário recupera senha
#    Dado que estou em "Recuperar senha"
#		E que eu preenchi "CPF" com "782.189.214-94"
#    	E que eu preenchi "E-mail" com "teste@virtual.ufc.br"
#	Quando eu clicar em "Enviar"
#    Então eu deverei ver "Senha enviada com sucesso"
