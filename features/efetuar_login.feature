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
	Cenário: Efetuar login com sucesso
		Dado que estou em "Login"
			E preencho o campo "login_form_nome" com "user"
			E preencho o campo "login_form_senha" com "user123"
		Quando eu clicar em "login_form_entrar"
		Então eu deverei ver "Home#index"

	Cenário: Tentativa de login - senha incorreta
		Dado que estou em "Login"
			E preencho o campo "login_form_nome" com "user"
			E preencho o campo "login_form_senha" com "wrong_password"
		Quando eu clicar em "login_form_entrar"
		Então eu deverei ver "Dados de login incorretos!"

	Cenário: Tentativa de login - usuário inexistente
		Dado que estou em "Login"
			E preencho o campo "login_form_nome" com "unknown_user"
			E preencho o campo "login_form_senha" com "any_password"
		Quando eu clicar em "login_form_entrar"
		Então eu deverei ver "Dados de login incorretos!"
