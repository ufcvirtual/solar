# language: pt

Funcionalidade: Filtros de edicao
  Como um usuario do solar
  Eu quero utilizar os filtros de edicao do sistema
  Para poder alcancar as devidas areas de edicao

Contexto:
  Dado que tenho "allocations"
    | user_id  | allocation_tag_id  | profile_id  | status |
    | 14       |                    | 5           | 1      |

@javascript
Cenário: Filtro de conteudo
  Dado que estou logado com o usuario "editor" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "Edição"
    Então eu deverei ver "Acadêmico"
    E eu deverei ver "Conteúdo"
  Quando eu clicar no link "Conteúdo"
    E eu deverei ver "Filtro"
    Dado que eu cliquei em "#search"
      Então eu deverei ver "Preencha os campos obrigatórios"
    Dado que eu preenchi "autocomplete-input" de "curriculum_unit_type" com "Curso de Graduacao a Distancia"
      Então eu deverei ver "Curso de Graduacao a Distancia"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "curriculum_unit_type"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "curriculum_unit_type"
    E que eu cliquei em "#search"
      Então eu nao deverei ver "Informação"
      E eu nao deverei ver "Comunicação"
      E eu nao deverei ver "Educação"
      E eu deverei ver "Preencha os campos obrigatórios"
    Dado que eu preenchi "autocomplete-input" de "course" com "LQUIM - Licenciatura em Quimica"
      Então eu deverei ver "LQUIM - Licenciatura em Quimica"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "course"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "course"
      E que eu cliquei em "#search"  
    Então eu deverei ver "Informação"
      E eu deverei ver "Comunicação"
      E eu deverei ver "Educação"
      E eu nao deverei ver "Preencha os campos obrigatórios"
    Dado que eu preenchi "autocomplete-input" de "curriculum_unit" com "Quimica"
      Então eu deverei ver "RM301 - Quimica I"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "curriculum_unit"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "curriculum_unit"
    E que eu cliquei em "#search"
      Então eu deverei ver "Informação"
      E eu deverei ver "Comunicação"
      E eu deverei ver "Educação"
    Dado que eu preenchi "autocomplete-input" de "semester" com "2011.1"
      Então eu deverei ver "2011.1"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "semester"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "semester"
    E que eu cliquei em "#search"
      Então eu deverei ver "Informação"
      E eu deverei ver "Comunicação"
      E eu deverei ver "Educação"

@javascript
Cenário: Filtro academico
  Dado que estou logado com o usuario "editor" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "Edição"
    Então eu deverei ver "Acadêmico"
    E eu deverei ver "Conteúdo"
  Quando eu clicar no link "Acadêmico"
    E eu deverei ver "Filtro"
    Dado que eu cliquei em "#search"
      Então eu deverei ver "Preencha os campos obrigatórios"
    Dado que eu preenchi "autocomplete-input" de "filter_type" com "Curso de Graduacao a Distancia"
      Então eu deverei ver "Curso de Graduacao a Distancia"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "filter_type"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "filter_type"
    E que eu cliquei em "#search"
      Então eu deverei ver "Cursos"
      E eu deverei ver "Unidades Curriculares"
      E eu deverei ver "Semestres"
      E eu deverei ver "Turmas"
    Dado que eu preenchi "autocomplete-input" de "filter_type" com "Curso Livre"
      Então eu deverei ver "Curso Livre"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "filter_type"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "filter_type"
    E que eu cliquei em "#search"
      Então eu deverei ver "Cursos"
      E eu deverei ver "Semestres"
      E eu deverei ver "Turmas"
    Dado que eu preenchi "autocomplete-input" de "filter_type" com "Curso de Extensao"
      Então eu deverei ver "Curso de Extensao"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "filter_type"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "filter_type"
    E que eu cliquei em "#search"
      Então eu deverei ver "Cursos"
      E eu deverei ver "Módulos"
      E eu deverei ver "Semestres"
      E eu deverei ver "Turmas"

@javascript 
Cenário: Filtro academico - cursos
  Dado que estou logado com o usuario "editor" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "Edição"
    Então eu deverei ver "Acadêmico"
  Quando eu clicar no link "Acadêmico"
    E eu deverei ver "Filtro"
    Dado que eu preenchi "autocomplete-input" de "filter_type" com "Curso de Graduacao a Distancia"
      Então eu deverei ver "Curso de Graduacao a Distancia"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "filter_type"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "filter_type"
      E que eu cliquei em "#search"
        Então eu deverei ver "Cursos"
    Dado que eu cliquei no link ".academic_item" de "courses"
      E eu deverei ver "Filtro"
      E eu deverei ver "Cursos"
    Dado que eu preenchi "autocomplete-input" de "filter" com "LQUIM - Licenciatura em Quimica"
      Então eu deverei ver "LQUIM - Licenciatura em Quimica"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "filter"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "filter"
      E que eu cliquei em "#search"
    Então eu deverei ver a linha de Cursos
      | Codigo        | Nome                          |
      | LQUIM         | Licenciatura em Quimica       |
    E eu nao deverei ver a linha de Cursos
      | Codigo        | Nome                          |
      | TS101         | Semipresencial sm nvista      |
    

@javascript
Cenário: Filtro academico - ucs
  Dado que estou logado com o usuario "editor" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "Edição"
    Então eu deverei ver "Acadêmico"
  Quando eu clicar no link "Acadêmico"
    E eu deverei ver "Filtro"
  Dado que eu preenchi "autocomplete-input" de "filter_type" com "Curso de Graduacao a Distancia"
    Então eu deverei ver "Curso de Graduacao a Distancia"
  Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "filter_type"
    E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "filter_type"
    E que eu cliquei em "#search"
      Então eu deverei ver "Unidades Curriculares"
    Dado que eu cliquei no link ".academic_item" de "curriculum_units"
      E eu deverei ver "Filtro"
      E eu deverei ver "Unidade Curricular"
    Dado que eu preenchi "autocomplete-input" de "filter" com "RM301 - Quimica I"
      Então eu deverei ver "RM301 - Quimica I"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "filter"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "filter"
      E que eu cliquei em "#search"
    Então eu deverei ver a linha de Unidade Curricular
      | Codigo        | Nome                          |
      | RM301         | Quimica I                     |
    E eu nao deverei ver a linha de Unidade Curricular
      | Codigo        | Nome                          |
      | TS101         | Semipresencial sm nvista      |
      | RM302         | Quimica Organica              |

@javascript
Cenário: Filtro academico - semestres
  Dado que estou logado com o usuario "editor" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "Edição"
    Então eu deverei ver "Acadêmico"
  Quando eu clicar no link "Acadêmico"
    E eu deverei ver "Filtro"
  Dado que eu preenchi "autocomplete-input" de "filter_type" com "Curso de Graduacao a Distancia"
    Então eu deverei ver "Curso de Graduacao a Distancia"
  Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "filter_type"
    E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "filter_type"
    E que eu cliquei em "#search"
      Então eu deverei ver "Semestres"
    Dado que eu cliquei no link ".academic_item" de "semesters"
      E eu deverei ver "Filtro"
      E eu deverei ver "2013.1"
    Dado que eu preenchi "autocomplete-input" de "period" com "Todos"
      Então eu deverei ver "Todos"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "period"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "period"
      E que eu cliquei em "#search"
    Então eu deverei ver "Selecione uma Unidade Curricular ou um Curso para pesquisar por todos."
    Dado que eu preenchi "autocomplete-input" de "period" com "Todos"
      Então eu deverei ver "Todos"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "period"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "period"
    Dado que eu preenchi "autocomplete-input" de "course" com "Licenciatura em Quimica"
      Então eu deverei ver "Licenciatura em Quimica"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "course"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "course"
    Dado que eu preenchi "autocomplete-input" de "curriculum_unit" com "Quimica I"
      Então eu deverei ver "Quimica I"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "curriculum_unit"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "curriculum_unit"
      E que eu cliquei em "#search"
    Então eu deverei ver "2012.1"
      E eu deverei ver a linha de Ofertas
        | Tipo                            | Curso                     | Unidade Curricular        |  Oferta                    |
        | Curso Livre                     | Letras Portugues          | Introducao a Linguistica  |  Mesmas datas do semestre  |
        | Curso de Graduacao a Distancia  | Licenciatura em Quimica   | Quimica I                 |  10/03/2011 - 01/12/2021   |

@javascript
Cenário: Filtro academico - turmas
  Dado que estou logado com o usuario "editor" e com a senha "123456"
    E que estou em "Meu Solar"
  Quando eu clicar no link "Edição"
    Então eu deverei ver "Acadêmico"
  Quando eu clicar no link "Acadêmico"
    E eu deverei ver "Filtro"
  Dado que eu preenchi "autocomplete-input" de "filter_type" com "Curso de Graduacao a Distancia"
    Então eu deverei ver "Curso de Graduacao a Distancia"
  Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "filter_type"
    E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "filter_type"
    E que eu cliquei em "#search"
      Então eu deverei ver "Semestres"
    Dado que eu cliquei no link ".academic_item" de "groups"
      E eu deverei ver "Filtro"
    Dado que eu cliquei em "#search"
      Então eu deverei ver "Preencha os campos obrigatórios"
    Dado que eu preenchi "autocomplete-input" de "course" com "LQUIM - Licenciatura em Quimica"
      Então eu deverei ver "LQUIM - Licenciatura em Quimica"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "course"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "course"
      E que eu cliquei em "#search"  
      E eu deverei ver "Preencha os campos obrigatórios"
    Dado que eu preenchi "autocomplete-input" de "curriculum_unit" com "Quimica I"
      Então eu deverei ver "RM301 - Quimica I"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "curriculum_unit"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "curriculum_unit"
    E que eu cliquei em "#search"
      Então eu deverei ver "Preencha os campos obrigatórios"
    Dado que eu preenchi "autocomplete-input" de "semester" com "2011.1"
      Então eu deverei ver "2011.1"
    Dado que eu pressionei a tecla "arrow_down" no campo "autocomplete-input" de "semester"
      E que eu pressionei a tecla "enter" no campo "autocomplete-input" de "semester"
    E que eu cliquei em "#search"
      Então eu deverei ver a linha de Turmas
        | Código |
        | QM-CAU |
        | QM-MAR |
        | TL-FOR |
