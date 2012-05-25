# language: pt
Funcionalidade: Exibir Foruns
  Como um usuario do solar
  Eu quero visualizar os foruns
  Para poder acessá-los

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 3                  | 1           | 1      |
        | 11       | 3                  | 3           | 1      |

Cenário: Exibir Foruns e entrar em fórum em andamento
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Fórum"
    Quando eu clicar no link "Fórum"
        Então eu deverei ver "Fóruns disponíveis"
        E eu deverei ver "Data de acesso"
        E eu deverei ver o link "Forum 1"
        E eu deverei ver o link "Forum 2"
    Quando eu clicar no link "Forum 1"
        Então eu deverei ver "Forum inicial para testes"
        E eu deverei ver "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        E eu deverei ver "Ricardo Palacio"
        #E eu deverei ver "Anexos"
        E eu deverei ver "Aluno"
        E eu deverei ver "Prof. Titular"
        E eu deverei ver "Tutor a Distancia"

Cenario: Exibir primeiro forum
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Fórum"
    Quando eu clicar no link "Fórum"
        Então eu deverei ver "Fóruns disponíveis"
        E eu deverei ver "Data de acesso"
        E eu deverei ver o link "Forum 2"
    Quando eu clicar no link "Forum 2"
        Então eu deverei ver "Segundo fórum de testes"
        E eu deverei ver "Sed quam nisl, commodo eget ullamcorper vel, lacinia vitae nunc."
        E eu deverei ver "Ricardo Palacio"
        E eu deverei ver "Tutor Presencial"
        E eu deverei ver "Aluno"
        E eu deverei ver o botao "Excluir"
        E eu deverei ver o botao "Editar"
        E eu deverei ver o botao "Responder"
        E eu deverei ver "Anexar arquivo"

Cenario: Exibir forum encerrado para aluno
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Fórum"
    Quando eu clicar no link "Fórum"
        Então eu deverei ver "Fóruns disponíveis"
        E eu deverei ver "Data de acesso"
        E eu deverei ver o link "Forum 1"
    Quando eu clicar no link "Forum 1"
        Então eu deverei ver "Forum inicial para testes"
        E eu deverei ver "In hac habitasse platea dictumst."
        E eu deverei ver "Ricardo Palacio"
        E eu deverei ver "Tutor a Distancia"
        E eu deverei ver "Aluno"
        E eu deverei ver "Fórum encerrado"

Cenário: Acessar Fórum como professor em período Extra
    Dado que estou logado com o usuario "tutordist" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Fórum"
    Quando eu clicar no link "Fórum"
        Então eu deverei ver "Fóruns disponíveis"
        E eu deverei ver "Data de acesso"
        E eu deverei ver o link "Forum 2"
        E eu deverei ver "(encerrado para alunos)"
    Quando eu clicar no link "Forum 2"
        Então eu deverei ver "Segundo fórum de testes"
        E eu deverei ver "Usuario do Sistema"
        E eu deverei ver "Sed quam nisl, commodo eget ullamcorper vel, lacinia vitae nunc."
