# language: pt
Funcionalidade: Exibir Foruns
  Como um usuario do solar
  Eu quero visualizar os foruns
  Para poder acessá-los


Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 3                  | 1           | 1      |


Cenário: Exibir Foruns
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Forum"
    Quando eu clicar no link "Forum"
        Então eu deverei ver "Fóruns disponíveis"
        E eu deverei ver "Data de acesso"
        E eu deverei ver o link "Forum 1"
    Quando eu clicar no link "Forum 1"
        Então eu deverei ver "Forum inicial para testes"
        E eu deverei ver "Ola, turma!"
        E eu deverei ver "Ricardo Palacio"
        E eu deverei ver "Anexos"
        E eu deverei ver "Aluno"
        E eu deverei ver "Prof. Titular"
        E eu deverei ver "Tutor a Distancia"


Cenario: Exibir segundo forum
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Forum"
    Quando eu clicar no link "Forum"
        Então eu deverei ver "Fóruns disponíveis"
        E eu deverei ver "Data de acesso"
        E eu deverei ver o link "Forum 2"
    Quando eu clicar no link "Forum 2"
        Então eu deverei ver "Segundo fórum de testes"
        E eu deverei ver "Bem vindos ao forum 2! Este forum eh legal."
        E eu deverei ver "Ricardo Palacio"
        E eu deverei ver "Tutor Presencial"
        E eu deverei ver "Aluno"
        E eu deverei ver o link "Excluir"
        E eu deverei ver o link "Editar"
        E eu deverei ver o link "Responder"
        E eu deverei ver o link "Anexar arquivo"
