#language: pt

Funcionalidade: Efetuar login
  Como um usuário do solar
  Eu quero efetuar login
  Para acessar os recursos do sistema

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        |                    | 12          | 1      |

@javascript
Cenário: Usuário já logado com step
	Dado que estou logado com o usuario "user" e com a senha "123456"
            E que estou em "Login"
	Então eu deverei visualizar "Unidade Curricular"

Cenário: Usuário não logado tenta acessar "Meu Solar"
	Dado que eu nao estou logado no sistema com usuario user
            E tento acessar "Meu Solar"
	Então eu deverei ver "Usuário"
	E eu deverei ver "Senha"

Esquema do Cenário: Login com usuários inválidos
	Dado que eu nao estou logado no sistema com usuario user
            E que estou em "Login"
            E preencho o campo "username" com "<login>"
            E preencho o campo "password" com "<password>"
	Quando eu clicar em "Entrar"
	Então eu deverei ver "<action>"
Exemplos:
	| login         |  password       |   action  		        |
	| unknown_user  |  any_password   | Usuário ou senha inválidos. |
	| user          |  wrong_password | Usuário ou senha inválidos. |

@javascript
Cenário:Login com usuário válido
        Dado que eu nao estou logado no sistema com usuario user
            E que estou em "Login"
            E preencho o campo "username" com "user"
            E preencho o campo "password" com "123456"
	Quando eu clicar em "Entrar"
	Então eu deverei visualizar "Unidade Curricular"

Cenário: Efetuar logout
	Dado que estou logado com o usuario "user" e com a senha "123456"
            E que estou em "Meu Solar"
	Quando eu clicar no link "Sair"
	Então eu deverei ver "Usuário"
	E eu deverei ver "Senha"


