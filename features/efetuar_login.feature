#language: pt

Funcionalidade: Efetuar login
  Como um usuário do solar
  Eu quero efetuar login
  Para acessar os recursos do sistema

Contexto:
	Dado que tenho "users"
		| login | email		| password |
		| user  | user@user.com | user123  |


@wip
	Cenário: Efetuar login
		Dado que estou em "Login"
			E preencho o campo "Login" com "user"
			E preencho o campo "Password" com "user123"
	Quando eu clicar em "Login"
		Então eu deverei ver "Home#index"
