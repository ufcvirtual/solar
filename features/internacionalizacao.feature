#language: pt

Funcionalidade: Internacionalizacao
  Como um usuário do solar
  Eu quero escolher uma língua
  Para compreender o conteúdo do site

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        |                    | 12          | 1      |

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
	Dado que estou logado com o usuario "user" e com a senha "123456"
            E que estou em "Meu Solar"
        Quando eu clicar no link "English"
        E eu clicar no link "my_data"
	Então eu deverei ver "Name"
            E eu deverei ver "Bio"
            E eu deverei ver "Interests"
            E eu deverei ver "Music"
            E eu deverei ver "Movies"
            E eu deverei ver "Books"
            E eu deverei ver "Phrase"
            E eu deverei ver "Site"
