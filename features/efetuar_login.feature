#language: pt

Funcionalidade: Efetuar login
  Como um usuário do solar
  Eu quero efetuar login
  Para acessar os recursos do sistema

Contexto:
	Dado que tenho "usuários"
		| login | email		| password | password_confirmation |
		| user  | user@user.com | user123  | user123		   |

@wip
	Cenário: Efetuar login
		Dado que estou em "Login"
			E preencho o campo "usuario" com "user"
			E preencho o campo "senha" com "user123"
	Quando eu clicar em "Entrar"
		Então eu deverei ver "Bem vindo ao Solar!"
