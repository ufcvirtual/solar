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

