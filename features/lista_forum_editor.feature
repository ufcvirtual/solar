# language: pt

Funcionalidade: Página de edição
  Como um usuario do solar
  Eu quero visualizar os itens da página de edição que tenho permissão
  Para poder acessá-los

Contexto:
  Dado que tenho "allocations"
    | user_id  | allocation_tag_id  | profile_id  | status |
    | 14       |                    | 5           | 1      |

 @javascript
Cenário: Exibir página e atualizar conteudo em div
  Dado que estou logado com o usuario "editor" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "Edição"
    Então eu deverei ver "Edição"
    E eu deverei ver "Filtro"
    # 2 = TL-CAU
    Dado que eu preenchi "token-input-places_nav_panel_txtGroup" com "TL"
      Então eu deverei ver "TL-CAU"
    Dado que eu pressionei a tecla "enter" no campo "token-input-places_nav_panel_txtGroup"
      Então eu deverei ver "Informação"
      E eu deverei ver "Comunicação"
      E eu deverei ver "Educação"
    Dado que eu cliquei em ".discussion"
    Então eu deverei ver "Edição"
    E eu deverei ver "Filtro"
    E eu deverei ver "Fóruns disponíveis"
      
