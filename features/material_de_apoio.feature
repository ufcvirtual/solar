# language: pt
Funcionalidade: Exibir Material de apoio
  Como um usuario do solar
  Eu quero visualizar o material de apoio
  Para poder acessá-las


Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 3                  | 1           | 1      |

Cenário: Exibir Material de apoio
    Dado que estou logado com o usuario "user" e com a senha "user123"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Conteudo"
    Quando eu clicar no link "Conteudo"
        Então eu deverei ver o link "Material de Apoio"
    Quando eu clicar no link "Material de Apoio"
        Então eu deverei ver "aulas"
        E eu deverei ver o link "1.pdf"
        E eu deverei ver o link "2.pdf"
        E eu deverei ver "fotos"
        E eu deverei ver o link "1.png"
        E eu deverei ver "outra pasta"
        E eu deverei ver o link "3.pdf"

