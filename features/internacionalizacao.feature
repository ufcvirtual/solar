#language: pt

Funcionalidade: Internacionalizacao
  Como um usuário do solar
  Eu quero escolher uma língua
  Para compreender o conteúdo do site

Contexto:
	Dado que tenho "users"
		| login | email		       | password | name   | birthdate  | cpf         | sex  | address | address_number | address_neighborhood | zipcode   | country | state | city      | institution | alternate_email    | bio                                                     | interests     | music                                                 | movies                      | books        | phrase         | site                      |
		| user  | teste@virtual.ufc.br | user123  | User01 | 01/01/2005 | 78218921494 | true | Rua R   | 111            | Bairro               | 600000000 | Brasil  | CE    | Fortaleza | UFC         | altemail@gmail.com | vencedor do torneio nordestão de counter strike em 2005 | sushi, festas | Jurandi Vieira, Dream Theather, Calypso, Eric Clapton | O homem de desafiou o Diabo | Harry Potter | Bato ou corro! | www.jacarebanguela.com.br |

Cenário: Login EN
        Dado que estou em "Login"
                E eu deverei ver "Senha"
        Quando eu clicar no link "English"
        Então eu deverei ver "Password"

Cenário: Login ptBR
        Dado que estou em "Login"
                E eu deverei ver "Senha"
        Quando eu clicar no link "English"
        E eu clicar no link "Português(BR)"
        Então eu deverei ver "Senha"

Cenário: Acessar página de Edição de Dados Pessoais em Ingles
	Dado que estou logado com o usuario "user" e com a senha "user123"
            E que estou em "Meu Solar"
        Quando eu clicar no link "English"
        E eu clicar no link "My Data"
	Então eu deverei ver "Name"
            E eu deverei ver "Bio"
            E eu deverei ver "Interests"
            E eu deverei ver "Music"
            E eu deverei ver "Movies"
            E eu deverei ver "Books"
            E eu deverei ver "Phrase"
            E eu deverei ver "Site"
