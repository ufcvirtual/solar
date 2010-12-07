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
			E preencho o campo "Usuário" com "user"
			E preencho o campo "Senha" com "user123"
		Quando eu clicar em "Entrar"
		Então eu deverei ver "Novidades"


	Cenário: Tentativa de login - senha incorreta
		Dado que estou em "Login"
			E preencho o campo "Usuário" com "user"
			E preencho o campo "Senha" com "wrong_password"
		Quando eu clicar em "Entrar"
		Então eu deverei ver "Dados de login incorretos!"


	Cenário: Tentativa de login - usuário inexistente
		Dado que estou em "Login"
			E preencho o campo "Usuário" com "unknown_user"
			E preencho o campo "Senha" com "any_password"
		Quando eu clicar em "Entrar"
		Então eu deverei ver "Dados de login incorretos!"


	Cenário: Usuário já logado 
		Dado que estou em "Login"
			E preencho o campo "Usuário" com "user"
			E preencho o campo "Senha" com "user123"
			E eu clicar em "Entrar"
			E eu deverei ver "Novidades"
			E vou para a pagina "Login"
		Então eu deverei ver "Novidades"


	Cenário: Usuário já logado com step
		Dado que estou logado no sistema
			E que estou em "Login"
		Então eu deverei ver "Novidades"


	Cenário: Usuário não logado tenta acessar "Meu Solar"
		Dado que eu nao estou logado
			E tento acessar "Meu Solar"
		Então eu deverei ver "Usuário"
		E eu deverei ver "Senha"


	Esquema do Cenário: Login com usuários válidos e inválidos
		Dado que eu nao estou logado
			E que estou em "Login"
			E preencho o campo "Usuário" com "<login>"
			E preencho o campo "Senha" com "<password>"
		Quando eu clicar em "Entrar"
		Então eu deverei ver "<action>"
	Exemplos:
		| login |  password   |   action  		   |
		| user  |  user123    | Novidades 		   |
		| error |  password   | Dados de login incorretos! |
		| user  |  error      | Dados de login incorretos! |


