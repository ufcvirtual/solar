# language: pt

Funcionalidade: Exibir Foruns
  Como um usuario do solar
  Eu quero visualizar os foruns
  Para poder acessá-los

@javascript
Cenário: Exibir Foruns e entrar em fórum em andamento
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "109 - Licenciatura em Quimica" em "td.course"
  Quando eu clicar no link "Fórum"
    Então eu deverei ver "Fóruns disponíveis"
    E eu deverei ver "Data de acesso"
    E eu deverei ver o link "Forum 1"
    E eu deverei ver o link "Forum 2"
  Quando eu clicar no link "Forum 2"
    Então eu deverei ver "O empenho em analisar o novo modelo estrutural aqui preconizado agrega valor ao estabelecimento do sistema de participação geral."
    E eu deverei ver "As experiências acumuladas demonstram que a estrutura atual da organização talvez venha a ressaltar a relatividade do investimento em reciclagem técnica."
    E eu deverei ver "User 2"
    E eu deverei ver "Aluno"
    E eu deverei ver "Tutor Presencial"

@javascript
Cenario: Exibir primeiro forum
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "109 - Licenciatura em Quimica" em "td.course"
  Quando eu clicar no link "Fórum"
    Então eu deverei ver "Fóruns disponíveis"
    E eu deverei ver "Data de acesso"
    E eu deverei ver o link "Forum 2"
  Quando eu clicar no link "Forum 2"
    Então eu deverei ver "O empenho em analisar o novo modelo estrutural aqui preconizado agrega valor ao estabelecimento do sistema de participação geral."
    E eu deverei ver "As experiências acumuladas demonstram que a estrutura atual da organização talvez venha a ressaltar a relatividade do investimento em reciclagem técnica."
    E eu deverei ver "User 2"
    E eu deverei ver "Tutor Presencial"
    E eu deverei ver "Aluno"
    E eu deverei ver o botao "Anexar" em mensagem com id "11"
    E eu deverei ver o botao "Excluir" em mensagem com id "11"
    E eu deverei ver o botao "Editar" em mensagem com id "11"
    E eu deverei ver o botao "Responder" em mensagem com id "11"

@javascript
Cenario: Exibir forum encerrado para aluno
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "109 - Licenciatura em Quimica" em "td.course"
  Quando eu clicar no link "Fórum"
    Então eu deverei ver "Fóruns disponíveis"
    E eu deverei ver "Data de acesso"
    E eu deverei ver o link "Forum 1"
  Quando eu clicar no link "Forum 1"
    Então eu deverei ver "No mundo atual, o fenômeno da Internet prepara-nos para enfrentar situações atípicas decorrentes dos conhecimentos estratégicos para atingir a excelência."
    E eu deverei ver "Por outro lado, a consolidação das estruturas exige a precisão e a definição do sistema de formação de quadros que corresponde às necessidades. "
    E eu deverei ver "User 2"
    E eu deverei ver "Prof. Titular"
    E eu deverei ver "Tutor a Distancia"
    E eu deverei ver "Aluno"
    E eu deverei ver "Fórum encerrado"

@javascript
Cenário: Acessar Fórum como professor em período Extra
  Dado que estou logado com o usuario "tutordist" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "109 - Licenciatura em Quimica" em "td.course"
  Quando eu clicar no link "Fórum"
    Então eu deverei ver "Fóruns disponíveis"
    E eu deverei ver "Data de acesso"
    E eu deverei ver o link "Forum 1"
    E eu deverei ver "(encerrado para alunos)"
  Quando eu clicar no link "Forum 1"
    Então eu deverei ver "No mundo atual, o fenômeno da Internet prepara-nos para enfrentar situações atípicas decorrentes dos conhecimentos estratégicos para atingir a excelência."
    E eu deverei ver "Usuario do Sistema"
    E eu deverei ver "Neste sentido, o acompanhamento das preferências de consumo apresenta tendências no sentido de aprovar a manutenção das formas de ação."
