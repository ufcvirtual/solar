#language: pt

Funcionalidade: Efetuar login
  Como um usuário do solar
  Eu quero efetuar login
  Para acessar os recursos do sistema

Cenário: Usuário já logado com step
	Dado que estou logado com o usuario "user" e com a senha "123456"
            E que estou em "Login"
	Então eu deverei ver "Unidade Curricular"

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
	| login         |  password       |   action  		        |
	| user          |  123456         | Unidade Curricular          |
	| unknown_user  |  any_password   | Usuário ou senha inválidos. |
	| user          |  wrong_password | Usuário ou senha inválidos. |

Cenário: Efetuar logout
	Dado que estou logado com o usuario "user" e com a senha "123456"
            E que estou em "Meu Solar"
	Quando eu clicar no link "Sair"
	Então eu deverei ver "Usuário"
	E eu deverei ver "Senha"


