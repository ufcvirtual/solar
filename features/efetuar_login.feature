#language: pt

Funcionalidade: Efetuar login
  Como um usuário do solar
  Eu quero efetuar login
  Para acessar os recursos do sistema

Contexto:
	Dado que tenho "users"
		| login | email		| password |
		| user  | user@user.com | user123  |

	Cenário: Efetuar login com sucesso
		Dado que estou em "Login"
			E preencho o campo "login_form_name" com "user"
			E preencho o campo "login_form_password" com "user123"
		Quando eu clicar em "login_form_entrar"
		Então eu deverei ver "Novidades"

@wip
	Cenário: Tentativa de login - senha incorreta
		Dado que estou em "Login"
			E preencho o campo "login_form_name" com "user"
			E preencho o campo "login_form_password" com "wrong_password"
		Quando eu clicar em "login_form_entrar"
		Então eu deverei ver "Dados de login incorretos!"

	Cenário: Tentativa de login - usuário inexistente
		Dado que estou em "Login"
			E preencho o campo "login_form_name" com "unknown_user"
			E preencho o campo "login_form_password" com "any_password"
		Quando eu clicar em "login_form_entrar"
		Então eu deverei ver "Dados de login incorretos!"


	Cenário: Usuário já logado 
		Dado que estou em "Login"
			E preencho o campo "login_form_name" com "user"
			E preencho o campo "login_form_password" com "user123"
			E eu clicar em "login_form_entrar"
			E eu deverei ver "Novidades"
			#E vou para "Login"
			E que estou em "Login"
		Então eu deverei ver "Novidades"


	Cenário: Usuário já logado com step
		Dado que estou logado no sistema
			E que estou em "Login"
		Então eu deverei ver "Novidades"

