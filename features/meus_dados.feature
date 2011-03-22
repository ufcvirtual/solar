#language: pt

Funcionalidade: Internacionalizacao
  Como um usuário do solar
  Eu quero editar meus dados
  Para atualizar as minhas informações no sistema

Contexto:
    Dado que tenho "users"
        | id | login | email		       | password | name   | birthdate  | cpf         | gender  | address | address_number | address_neighborhood | zipcode   | country | state | city      | institution | alternate_email    | bio                                                     | interests     | music                                                 | movies                      | books        | phrase         | site                      |
        | 1  | user  | teste@virtual.ufc.br | user123  | User01 | 01/01/2005 | 78218921494 | true | Rua R   | 111            | Bairro               | 600000000 | Brasil  | CE    | Fortaleza | UFC         | altemail@gmail.com | vencedor do torneio nordestão de counter strike em 2005 | sushi, festas | Jurandi Vieira, Dream Theather, Calypso, Eric Clapton | O homem de desafiou o Diabo | Harry Potter | Bato ou corro! | www.jacarebanguela.com.br |
    Dado que tenho "personal_configurations"
        | user_id | default_locale |
        | 1       | pt-BR |

Cenário: Acessar página de Edição de Dados Pessoais
	Dado que estou logado com o usuario "user" e com a senha "user123"
            E que estou em "Meus Dados"
	Então eu deverei ver "Nome"
            E eu deverei ver "Bio"
            E eu deverei ver "Interesses"
            E eu deverei ver "Música"
            E eu deverei ver "Filmes"
            E eu deverei ver "Livros"
            E eu deverei ver "Frase"
            E eu deverei ver "Site"


Cenário: Acessar página de Edição de Dados Cadastrais
	Dado que estou logado com o usuario "user" e com a senha "user123"
            E que estou em "Meus Dados"
	Então eu deverei ver "Nome"
            E eu deverei ver "Apelido"
            E eu deverei ver "Data de Nascimento"
            E eu deverei ver "Sexo"
            E eu deverei ver "CPF"
            E eu deverei ver "Contato"
            E eu deverei ver "E-mail"
            E eu deverei ver "E-mail alternativo"
            E eu deverei ver "Telefone"
            E eu deverei ver "Instituição"
            E eu deverei ver "Endereço"
            E eu deverei ver "Rua"
            E eu deverei ver "Número"
            E eu deverei ver "Cidade"
            E eu deverei ver "CEP"
            E eu deverei ver "Estado"
            E eu deverei ver "Bairro"
            E eu deverei ver "País"
            E eu deverei ver "Autenticação"
            E eu deverei ver "Login"
            E eu deverei ver "Senha"
            E eu deverei ver "Necessidades especiais"


Cenário: Alterar dados Pessoais
       Dado que estou logado com o usuario "user" e com a senha "user123"
           E que estou em "Meus Dados"
           E que eu preenchi "Nome" com "Jurandi"
           E que eu preenchi "user_bio" com "Bicampeao Estadual em 94 e 95"
           E que eu preenchi "Interesses" com "Leitura e paz mundial"
           E que eu preenchi "Música" com "MPB forró reaggue e Restart"
           E que eu preenchi "Filmes" com "The Fighters 2010"
           E que eu preenchi "Livros" com "The Hobbit"
           E que eu preenchi "Frase" com "Bazzinga"
           E que eu preenchi "Site" com "www.kibeloco.com.br"
    Quando eu clicar em "personal_submit"
    Então eu deverei ver "Usuário alterado com sucesso!"


Cenário: Alterar dados Cadastrais
   Dado que estou logado com o usuario "user" e com a senha "user123"
       E que estou em "Meus Dados"
       E que eu preenchi "Nome" com "Usuário do Solar"
       E que eu preenchi "Apelido" com "usuario"
       E que eu selecionei a data "13/12/2001" no campo com id "user_birthdate"
       E que eu selecionei "Sexo" com "Masculino"
       E que eu preenchi "cpf" com "72416475304"
       E que eu preenchi "E-mail" com "usuario@solar.virtual.ufc.br"
       E que eu preenchi "E-mail alternativo" com "alexiei@solar.virtual.ufc.br"
       E que eu preenchi "telefone" com "8533222233"
       E que eu preenchi "Instituição" com "Elzir Cabral"
       E que eu preenchi "Rua" com "Rua Sei Não"
       E que eu preenchi "Número" com "123"
       E que eu preenchi "cep" com "60000000"
       E que eu preenchi "Bairro" com "Sei lá qual"
       E que eu preenchi "Cidade" com "Fortaleza"
       E que eu selecionei "Estado" com "CE"
       E que eu preenchi "País" com "Brasil"
       E que eu preenchi "Login" com "usuario"
    Quando eu clicar em "cadastral_submit"
    Então eu deverei ver "Usuário alterado com sucesso!"

Esquema do Cenário: Alteração de senha
	Dado que estou logado com o usuario "user" e com a senha "user123"
		E que estou em "Meus Dados"
		E preencho o campo "Senha Antiga" com "<antiga_senha>"
		E preencho o campo "Nova Senha" com "<nova_senha>"
                E preencho o campo "Confirmar Senha" com "<confirmar_senha>"
	Quando eu clicar em "cadastral_submit"
	Então eu deverei ver "<action>"
Exemplos:
	| antiga_senha         |  nova_senha       |  confirmar_senha      | action                                        |
	| xyz                  |                   |                       | Senha antiga incorreta                        |
        | xyz                  |  user456          |  user456              | Senha antiga incorreta                        |
        | user123              |                   |                       | A nova senha e a confirmação não conferem!    |
        | user123              |  user456          |  user789              | A nova senha e a confirmação não conferem!    |
        |                      |  user456          |  user456              | Senha antiga vazia                            |
        |                      |  user456          |  user789              | Senha antiga vazia                            |
        | user123              |                   |  user789              | A nova senha e a confirmação não conferem!    |
        | user123              |  user789          |                       | A nova senha e a confirmação não conferem!    |
        | xyz                  |                   |  user789              | Senha antiga incorreta                        |
        | xyz                  |  user789          |                       | Senha antiga incorreta                        |
        |                      |                   |  user789              | Senha antiga vazia                            |
        |                      |  user789          |                       | Senha antiga vazia                            |      
        | user123              |  user789          |  user789              | Usuário alterado com sucesso!                 |

Cenário:  Acessar Edição de foto
    Dado que estou logado com o usuario "user" e com a senha "user123"
       E que estou em "Meu Solar"
    Então eu deverei ver "Do seu computador"
    E eu deverei ver "De um link externo"
    E eu deverei ver o botao "Cancelar"
    E eu deverei ver o botao "Enviar"

Esquema do Cenário: Enviar foto
    Dado que estou logado com o usuario "user" e com a senha "user123"
       E que estou em "Meu Solar"
       E eu envio o arquivo "<foto>" no campo "user_photo"
    Quando eu clicar em "photo_submit"
    Então eu deverei ver "<saida>"
Exemplos:
	| foto                                                    | saida                                                                               |
	| images/photo_valid.png                                  | Foto alterada com sucesso!                                                          |
	| images/photo_valid_no_extension                         | Foto alterada com sucesso!                                                          |
	| images/photo_invalid_type.txt                           | Tipo de arquivo inválido. Por favor, envie apenas arquivos do tipo JPG, GIF ou PNG. |
	| images/photo_invalid_type_size_and_valid_extension.png  | Arquivo muito grande. O tamanho máximo da sua foto deve ser de até 700KB.           |
	| images/photo_invalid_size.png                           | Arquivo muito grande. O tamanho máximo da sua foto deve ser de até 700KB.           |
	| images/photo_invalid_type_and_valid_extension.png       | Tipo de arquivo inválido. Por favor, envie apenas arquivos do tipo JPG, GIF ou PNG. |
	| images/photo_invalid_no_extension                       | Tipo de arquivo inválido. Por favor, envie apenas arquivos do tipo JPG, GIF ou PNG. |
    
