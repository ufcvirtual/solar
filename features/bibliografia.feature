# language: pt
Funcionalidade: Exibir biliografias da oferta
  Como um usuario do solar
  Eu quero visualizar as bibliografias da oferta
  Para poder acessá-las

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 3                  | 2           | 1      |

Cenário: Exibir bibliografia
    Dado que estou logado com o usuario "user" e com a senha "user123"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Informações Gerais"
    Quando eu clicar no link "Informações Gerais"
        Então eu deverei ver o link "Bibliografia"
    Quando eu clicar no link "Bibliografia"
        Então eu deverei ver "Bibliografia de Quimica I"
        E eu deverei ver "Metodos ageis em POG"
        E eu deverei ver "PATAO , Rafael. Metodos ageis em POG . 1.ed . Trantor: Ursa menor , 2020. Finibus Bonorum et Malorum by Cicero are also reproduced in their exact original form."