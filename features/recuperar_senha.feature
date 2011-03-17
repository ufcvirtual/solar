#language: pt

Funcionalidade: Recuperar senha
  Como um usuário do solar
  Eu quero recuperar minha senha
  Para acessar os recursos do sistema

Contexto:
    Dado que tenho "users"
        | id | login | email		           | password | name   | birthdate  | cpf         | sex  | address | address_number | address_neighborhood | zipcode   | country | state | city      | institution | alternate_email    |
        | 1  | user  | teste@virtual.ufc.br | user123  | User01 | 01/01/2005 | 78218921494 | true | Rua R   | 111            | Bairro               | 600000000 | Brasil  | CE    | Fortaleza | UFC         | altemail@gmail.com |
    Dado que tenho "personal_configurations"
        | user_id | default_locale |
        | 1       | pt-BR |

Cenário: Usuário acessa tela de recuperação de senha
	Dado que estou em "Login"
		E eu clico no link "esqueci a senha"
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
