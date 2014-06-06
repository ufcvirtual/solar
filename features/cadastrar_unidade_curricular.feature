# language: pt
Funcionalidade: Cadastrar e Editar Unidade Curricular
  Como um usuario do solar com permissão de editar unidades curriculares
  Eu quero ver a lista, criar, editar e excluir de unidades curriculares

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 1                  | 3           | 1      |
        | 2        | 1                  | 2           | 1      |
        | 14       | 7                  | 5           | 1      |
        | 14       | 12                 | 5           | 1      |

Cenário: Acessar listagem de unidades curriculares como usuário com permissão para isso
Dado que estou logado com o usuario "editor" e com a senha "123456"
  E que estou em "Cadastro de Unidade Curricular - Graduacao a Distancia"
    Então eu deverei ver "btn_new_curriculum_unit"
    E eu deverei ver a linha de Unidade Curricular
      | Codigo        | Nome                          | Categoria                             |
      | RM301         | Quimica I                     | Curso de Graduacao a Distancia        |
      | TS101         | Semipresencial sm nvista      | Curso de Graduacao a Distancia        |
    E eu nao deverei ver a linha de Unidade Curricular
      | Codigo        | Nome                          | Categoria                             |
      | RM414         | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial     |
      | RM404         | Introducao a Linguistica      | Curso Livre                           |
      | RM405         | Teoria da Literatura I        | Curso de Graduacao Presencial         |

Cenário: Tentar acessar listagem de unidades curriculares como usuário sem permissão para isso
Dado que estou logado com o usuario "user" e com a senha "123456"
  E que estou em "Cadastro de Unidade Curricular - Graduacao a Distancia"
  Então eu deverei ver "Você não tem permissão para acessar esta página"

@javascript
Cenário: Criar e excluir unidade curricular como usuário com permissão para isso
Dado que estou logado com o usuario "editor" e com a senha "123456"
  E que estou em "Cadastro de Unidade Curricular - Graduacao a Distancia"
  E eu deverei ver "btn_new_curriculum_unit"
  Dado que eu cliquei em "#btn_new_curriculum_unit"
  E que eu preenchi "Nome" com "Unidade Curricular IV"
  E que eu preenchi "Código" com "UC0004"
  E que eu preenchi "Média" com "8"
  E que eu preenchi "Resumo" com "Resumo da Unidade Curricular IV"
  E que eu preenchi "Ementa" com "Ementa da Unidade Curricular IV"
  E que eu preenchi "Objetivos" com "Objetivos da Unidade Curricular IV"
  E que eu preenchi "Pré-requisitos" com "Pré-requisitos da Unidade Curricular IV"
  Quando eu clicar em "Salvar"
    Entao eu deverei ver "Unidade Curricular criada com sucesso."
      E eu deverei ver a linha de Unidade Curricular
        | Codigo        | Nome                          | Categoria                             |
        | UC0004        | Unidade Curricular IV         | Curso de Graduacao a Distancia        |
      E eu nao deverei ver a linha de Unidade Curricular
        | Codigo        | Nome                          | Categoria                             |
        | RM414         | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial     |
  #Quando eu clicar no botao ".delete_curriculum_unit" da linha que contem o item "UC0004" da tabela
  #  Entao a pagina deve aceitar a proxima confirmacao
  #    E eu deverei ver "Unidade Curricular deletada com sucesso."
  #    E eu nao deverei ver a linha de Unidade Curricular
  #      | Codigo        | Nome                          | Categoria                             |
  #      | UC0004        | Unidade Curricular IV         | Curso de Graduacao Presencial         |

@javascript
Cenário: Criar unidade curricular com dado inválido
Dado que estou logado com o usuario "editor" e com a senha "123456"
  E que estou em "Cadastro de Unidade Curricular - Graduacao a Distancia"
  E eu deverei ver "btn_new_curriculum_unit"
  Dado que eu cliquei em "#btn_new_curriculum_unit"
    E que eu preenchi "Nome" com "Unidade Curricular IV"
    E que eu preenchi "Código" com "UC0004"
    E que eu preenchi "Média" com "8"
    E que eu preenchi "Resumo" com ""
    E que eu preenchi "Ementa" com "Ementa da Unidade Curricular IV"
    E que eu preenchi "Objetivos" com "Objetivos da Unidade Curricular IV"
    E que eu preenchi "Pré-requisitos" com "Pré-requisitos da Unidade Curricular IV"
    Quando eu clicar em "Salvar"
      Entao eu deverei ver "obrigatório"

@javascript
Cenário: Editar uma unidade curricular como usuário com permissão para isso
Dado que estou logado com o usuario "editor" e com a senha "123456"
  E que estou em "Cadastro de Unidade Curricular - Graduacao a Distancia"
  Quando eu clicar no botao ".edit" da linha que contem o item "Quimica I" da tabela
    E preencho o campo "Nome" com "Quimica I v2.75"
  Quando eu clicar em "Salvar"
    Entao eu deverei ver "Unidade Curricular atualizada com sucesso"
  E eu deverei ver a linha de Unidade Curricular
    | Codigo        | Nome                          | Categoria                             |
    | RM301         | Quimica I v2.75               | Curso de Graduacao a Distancia        |
  E eu nao deverei ver a linha de Unidade Curricular
    | Codigo        | Nome                          | Categoria                             |
    | RM414         | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial     |

#@javascript
#Cenário: Excluir uma unidade curricular com alocações além da do usuário que tentará fazer a exclusão
#Dado que estou logado com o usuario "editor" e com a senha "123456"
#    E que estou em "Cadastro de Unidade Curricular - Graduacao a Distancia"
#    Quando eu clicar no botao ".delete_curriculum_unit" da linha que contem o item "Quimica I" da tabela
#      #Então a pagina deve aceitar a proxima confirmacao
#        E eu deverei ver "Não foi possível deletar Unidade Curricular."
#        E eu deverei ver a linha de Unidade Curricular
#          | Codigo        | Nome                          | Categoria                             |
#          | RM301         | Quimica I                     | Curso de Graduacao a Distancia        |
