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
    Então eu deverei ver "Acadêmico"
    E eu deverei ver "Conteúdo"
  Quando eu clicar no link "Conteúdo"
    E eu deverei ver "Filtro"
    Dado que eu preenchi "autocomplete-input" de "curriculum_unit_type" com "Curso de Graduacao a Distancia"
      Então eu deverei ver "Curso de Graduacao a Distancia"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "curriculum_unit_type"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "curriculum_unit_type"
    Dado que eu preenchi "autocomplete-input" de "course" com "Quimica"
      Então eu deverei ver "109 - Licenciatura em Quimica"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "course"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "course"
    Dado que eu preenchi "autocomplete-input" de "curriculum_unit" com "Quimica"
      Então eu deverei ver "RM301 - Quimica I"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "curriculum_unit"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "curriculum_unit"
    Dado que eu preenchi "autocomplete-input" de "semester" com "2011.1"
      Então eu deverei ver "2011.1"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "semester"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "semester"
    E que eu cliquei em "#search"
      Então eu deverei ver "Informação"
      E eu deverei ver "Comunicação"
      E eu deverei ver "Educação"
    Dado que eu cliquei em ".lesson"
      Então eu deverei ver "Ordem"
      E eu deverei ver "Nome da aula"
      E eu deverei ver "Disponibilidade"
