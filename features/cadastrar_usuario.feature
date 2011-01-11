#language: pt

Funcionalidade: Cadastrar usuário
  Como um novo usuário do solar
  Eu quero me cadastrar
  Para acessar os recursos do sistema

Cenário: Acessar página de cadastro de novo usuário
	Dado que eu nao estou cadastrado
		E que estou em "Login"
		E eu clico no link "Cadastrar"
	Então eu deverei ver "Nome"
		E eu deverei ver "CPF"
		E eu deverei ver "Sexo"
		E eu deverei ver "Data de nascimento"
		E eu deverei ver "Necessidades Especiais"
		E eu deverei ver "Endereço"
		E eu deverei ver "Número"
		E eu deverei ver "Complemento"
		E eu deverei ver "Bairro"
		E eu deverei ver "CEP"
		E eu deverei ver "Estado"
		E eu deverei ver "Município"
		E eu deverei ver "País"
		E eu deverei ver "Telefone"
		E eu deverei ver "Celular"
		E eu deverei ver "Instituição"
		E eu deverei ver "Apelido"
		E eu deverei ver "Email"
		E eu deverei ver "Login"
		E eu deverei ver "Senha"
		E eu deverei ver o botao "Salvar"
@wip
Cenário: Cadastrar novo usuário
    Dado que estou em "Cadastrar usuario"
       E que eu preenchi "Nome" com "Usuário do Solar"
       E que eu preenchi "CPF" com "12345678901"
       E que eu selecionei "Sexo" com "M"
       E que eu selecionei a data "13/12/2010" no campo com id "user_birthdate"
       E que eu preenchi "Qual" com "Unha encravada"
       E que eu preenchi "Endereço" com "Rua Sei Não"
       E que eu preenchi "Número" com "123"
       E que eu preenchi "Complemento" com "Ap 000"
       E que eu preenchi "Bairro" com "Sei lá qual"
       E que eu preenchi "CEP" com "60000000"
       E que eu selecionei "Estado" com "CE"
       E que eu preenchi "Município" com "Fortaleza"
       E que eu preenchi "País" com "Brasil"
       E que eu preenchi "Telefone" com "8533222233"
       E que eu preenchi "Celular" com "8588888888"
       E que eu preenchi "Instituição" com "Inst"
       E que eu preenchi "Nick" com "Usuário"
       E que eu preenchi "E-mail" com "usuario@solar.virtual.ufc.br"
       E que eu preenchi "Login" com "usuario"
       E que eu preenchi "Senha" com "123456"
    Quando eu clicar no link da imagem "confirmar"
    Então eu deverei ver "Usuario criado com sucesso!"

