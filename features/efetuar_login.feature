#language: pt

Funcionalidade: Efetuar login
  Como um usuário do solar
  Eu quero efetuar login
  Para acessar os recursos do sistema

Contexto:
	Dado que tenho "users"
		| id | login | email		| password | name | birthdate  | cpf         | gender  | address | address_number | address_neighborhood | zipcode   | country | state | city      | institution |
		| 1  | user  | user@user.com | user123  | Username | 01/01/2005 | 78218921494 | true | Rua R   | 111            | Bairro               | 600000000 | Brasil  | CE    | Fortaleza | UFC         |
        Dado que tenho "personal_configurations"
                | user_id | default_locale |
                | 1       | pt-BR          |

Cenário: Usuário já logado com step
	Dado que estou logado com o usuario "user" e com a senha "user123"
		E que estou em "Login"
	Então eu deverei ver "Agenda"

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
	| user          |  user123        | Agenda 		   |
	| unknown_user  |  any_password   | Dados de login incorretos! |
	| user          |  wrong_password | Dados de login incorretos! |

Cenário: Efetuar logout
	Dado que estou logado com o usuario "user" e com a senha "user123"
		E que estou em "Meu Solar"
	Quando eu clicar no link "Sair"
	Então eu deverei ver "Usuário"
	E eu deverei ver "Senha"


