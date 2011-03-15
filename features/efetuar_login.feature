#language: pt

Funcionalidade: Efetuar login
  Como um usuário do solar
  Eu quero efetuar login
  Para acessar os recursos do sistema

Contexto:
	Dado que tenho "users"
		| login | email		| password | name | birthdate  | cpf         | sex  | address | address_number | address_neighborhood | zipcode   | country | state | city      | institution |
		| user  | user@user.com | user123  | Username | 01/01/2005 | 78218921494 | true | Rua R   | 111            | Bairro               | 600000000 | Brasil  | CE    | Fortaleza | UFC         |

Cenário: Usuário já logado com step
	Dado que estou logado com o usuario "user" e com a senha "user123"
		E que estou em "Login"
	Então eu deverei ver "Novidades"

Cenário: Usuário não logado tenta acessar "Meu Solar"
	Dado que eu nao estou logado no sistema com usuario user
		E tento acessar "Meu Solar"
	Então eu deverei ver "Usuário"
	E eu deverei ver "Senha"

Esquema do Cenário: Login com usuários válidos e inválidos
	Dado que eu nao estou logado no sistema com usuario user
		E que estou em "Login"
		E preencho o campo "Usuário" com "<login>"
		E preencho o campo "Senha" com "<password>"
	Quando eu clicar em "Entrar"
	Então eu deverei ver "<action>"
Exemplos:
	| login         |  password       |   action  		   |
	| user          |  user123        | Novidades 		   |
	| unknown_user  |  any_password   | Dados de login incorretos! |
	| user          |  wrong_password | Dados de login incorretos! |

Cenário: Efetuar logout
	Dado que estou logado com o usuario "user" e com a senha "user123"
		E que estou em "Meu Solar"
	Quando eu clicar no link "Sair"
	Então eu deverei ver "Usuário"
	E eu deverei ver "Senha"


