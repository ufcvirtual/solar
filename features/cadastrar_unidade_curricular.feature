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
        | 14       | 13                 | 5           | 1      |

Cenário: Acessar listagem de unidades curriculares como usuário com permissão para isso
Dado que estou logado com o usuario "editor" e com a senha "123456"
        E que estou em "Cadastro de Unidade Curricular"
        Então eu deverei ver o botao "Nova"
        E eu deverei ver a linha de Unidade Curricular
        | Codigo        | Nome                          | Categoria                             |
        | RM404         | Introducao a Linguistica      | Curso Livre                           |
        | RM301         | Quimica I                     | Curso de Graduacao a Distancia        |
        | RM405         | Teoria da Literatura I        | Curso de Graduacao Presencial         |
        E eu nao deverei ver a linha de Unidade Curricular
        | Codigo        | Nome                          | Categoria                             |
        | RM414         | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial     |

Cenário: Tentar acessar listagem de unidades curriculares como usuário sem permissão para isso
Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Cadastro de Unidade Curricular"
        Então eu deverei ver "Você não tem permissão para acessar esta página"

@javascript
Cenário: Criar e excluir unidade curricular como usuário com permissão para isso
Dado que estou logado com o usuario "editor" e com a senha "123456"
        E que estou em "Cadastro de Unidade Curricular"
        E eu deverei ver o botao "Nova"
        Quando eu clicar em "Nova"
        E que eu selecionei "Categoria" com "Curso de Graduacao Presencial"
        E que eu preenchi "Nome" com "Unidade Curricular IV"
        E que eu preenchi "Código" com "UC0004"
        E que eu preenchi "Média" com "8"
        E que eu preenchi "Resumo" com "Resumo da Unidade Curricular IV"
        E que eu preenchi "Ementa" com "Ementa da Unidade Curricular IV"
        E que eu preenchi "Objetivos" com "Objetivos da Unidade Curricular IV"
        E que eu preenchi "Pré-requisitos" com "Pré-requisitos da Unidade Curricular IV"
        Quando eu clicar em "Confirmar"
                Entao eu deverei ver "Unidade Curricular IV foi criado(a) com sucesso."
                E eu deverei ver a linha de Unidade Curricular
                        | Codigo        | Nome                          | Categoria                             |
                        | UC0004        | Unidade Curricular IV         | Curso de Graduacao Presencial         |
                E eu nao deverei ver a linha de Unidade Curricular
                        | Codigo        | Nome                          | Categoria                             |
                        | RM414         | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial     |
        Quando eu clicar no botao "Excluir" da linha que contem o item "UC0004" da tabela
                E eu clicar em "Ok" no popup
        Entao eu deverei ver "Unidade Curricular IV foi excluído(a) com sucesso."
                E eu nao deverei ver a linha de Unidade Curricular
                | Codigo        | Nome                          | Categoria                             |
                | UC0004        | Unidade Curricular IV         | Curso de Graduacao Presencial         |


@javascript
Cenário: Criar unidade curricular com dado inválido
Dado que estou logado com o usuario "editor" e com a senha "123456"
        E que estou em "Cadastro de Unidade Curricular"
        E eu deverei ver o botao "Nova"
        Quando eu clicar em "Nova"
        E que eu selecionei "Categoria" com "Curso de Graduacao Presencial"
        E que eu preenchi "Nome" com "Unidade Curricular IV"
        E que eu preenchi "Código" com "UC0004"
        E que eu preenchi "Média" com "8"
        E que eu preenchi "Resumo" com ""
        E que eu preenchi "Ementa" com "Ementa da Unidade Curricular IV"
        E que eu preenchi "Objetivos" com "Objetivos da Unidade Curricular IV"
        E que eu preenchi "Pré-requisitos" com "Pré-requisitos da Unidade Curricular IV"
        Quando eu clicar em "Confirmar"
        Entao eu deverei ver "deve ser preenchido(a)"

@javascript
Cenário: Editar uma unidade curricular como usuário com permissão para isso
Dado que estou logado com o usuario "editor" e com a senha "123456"
        E que estou em "Cadastro de Unidade Curricular"
        Quando eu clicar no botao "Editar" da linha que contem o item "Quimica I" da tabela
                E preencho o campo "Nome" com "Quimica I v2.75"
        Quando eu clicar em "Confirmar"
                Entao eu deverei ver "Quimica I v2.75 foi atualizado(a) com sucesso."
        E eu deverei ver a linha de Unidade Curricular
        | Codigo        | Nome                          | Categoria                             |
        | RM301         | Quimica I v2.75               | Curso de Graduacao a Distancia        |
        E eu nao deverei ver a linha de Unidade Curricular
        | Codigo        | Nome                          | Categoria                             |
        | RM414         | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial     |


@javascript
Cenário: Excluir uma unidade curricular com alocações além da do usuário que tentará fazer a exclusão
Dado que estou logado com o usuario "editor" e com a senha "123456"
        E que estou em "Cadastro de Unidade Curricular"
        Quando eu clicar no botao "Excluir" da linha que contem o item "Quimica I" da tabela
        E eu clicar em "Ok" no popup
        Entao eu deverei ver "Quimica I possui associações quem impedem sua exclusão!"
        E eu deverei ver a linha de Unidade Curricular
        | Codigo        | Nome                          | Categoria                             |
        | RM301         | Quimica I                     | Curso de Graduacao a Distancia        |
