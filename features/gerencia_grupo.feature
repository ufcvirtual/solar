# language: pt
Funcionalidade: Exibir Página de Grupos de Portfolio
  Como um usuário do solar
  Eu quero listar os trabalhos de grupo disponíveis
  Para poder gerenciar os grupos de trabalho

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 3                  | 3           | 1      |
        | 7        | 3                  | 1           | 1      |

Cenário: Exibir Tela de Cadastro de Trabalho de Grupo
    Dado que estou logado com o usuario "prof" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Grupos"
    Quando eu clicar no link "Grupos"
        Então eu deverei ver "Atividade em grupo I"
        E eu deverei ver "Atividade em grupo II"
        E eu nao deverei ver "Atividade I"
        E eu nao deverei ver "Atividade II"
        E eu nao deverei ver "Atividade III"

#@javascript
#Cenário: Exibir Grupos de Trabalho
#    Dado que estou logado com o usuario "prof" e com a senha "123456"
#        E que estou em "Meu Solar"
#    Quando eu clicar no link "Quimica I"
#        Então eu deverei ver "Atividades"
#    Quando eu clicar no link "Atividades"
#        Então eu deverei ver o link "Grupos"
#    Quando eu clicar no link "Grupos"
#        Então eu deverei ver "Atividade em grupo I"
#        Então eu deverei ver "Atividade em grupo II"
#    Quando eu clicar no link "Atividade em grupo I"
#        Então eu deverei ver "grupo1 tI"
#        E eu deverei ver "grupo2 tI"
#        E eu deverei ver "grupo3 tI"
#    Quando eu clicar no item "Atividade em grupo II" de id "5"
#        Então eu deverei ver "grupo1 - tII"
#        E eu deverei ver "grupo2 - tII"

#@javascript
#Cenário: Acessar página que tem o botão de importação de grupo
#    Dado que estou logado com o usuario "prof" e com a senha "123456"
#        E que estou em "Meu Solar"
#    Quando eu clicar no link "Quimica I"
#        Então eu deverei ver "Atividades"
#    Quando eu clicar no link "Atividades"
#        Então eu deverei ver o link "Grupos"
#    Quando eu clicar no link "Grupos"
#        Então eu deverei ver "Atividade em grupo I"
#        E eu deverei ver "Atividade em grupo II"
#        E eu deverei ver "Atividade em grupo III"
#    Quando eu clicar no item "Atividade em grupo I" de id "4"
#        Então eu nao deverei ver o elemento de id "import_to_4"
#    Quando eu clicar no item "Atividade em grupo III" de id "import_to_6"
#        Então eu deverei ver o elemento de id "6"

#@javascript
#Cenário: Acessar lightbox importação de grupo
#    Dado que estou logado com o usuario "prof" e com a senha "123456"
#        E que estou em "Meu Solar"
#    Quando eu clicar no link "Quimica I"
#        Então eu deverei ver "Atividades"
#    Quando eu clicar no link "Atividades"
#        Então eu deverei ver o link "Grupos"
#    Quando eu clicar no link "Grupos"
#        Então eu deverei ver "Atividade em grupo III"
#    Quando eu clicar no item "Atividade em grupo III" de id "import_to_6"
#        Então eu deverei ver o elemento de id "import_to_6"
#    Quando eu clicar no botao de importacao de id "6"
#        Então eu deverei aguardar "3" segundos
#        E eu deverei ver o elemento de id "lightBoxDialog"

#@javascript
#Cenário: Importar grupos pelo lightbox
#    Dado que estou logado com o usuario "prof" e com a senha "123456"
#        E que estou em "Meu Solar"
#    Quando eu clicar no link "Quimica I"
#        Então eu deverei ver "Atividades"
#    Quando eu clicar no link "Atividades"
#        Então eu deverei ver o link "Grupos"
#    Quando eu clicar no link "Grupos"
#        Então eu deverei ver "Atividade em grupo III"
#    Quando eu clicar no item "Atividade em grupo III" de id "6"
#        Então eu deverei ver o elemento de id "import_to_6"
#    Quando eu clicar no botao de importacao de id "6"
#        Então eu deverei aguardar "2" segundos
#        E eu deverei ver o elemento de id "lightBoxDialog"
#        E eu deverei ver o elemento de id "name_4"
#        E eu deverei ver o elemento de id "name_5"
#        E eu nao deverei ver o elemento de id "name_6"
#    Quando eu clicar no item "Atividade em grupo I" de id "import_4"
#        Então eu deverei ver "grupo1 tI"
#        E eu deverei ver "grupo2 tI"
#        E eu deverei ver "grupo3 tI"
#        E eu deverei ver o botao "Importar"
#        E eu deverei ver o botao "Cancelar"
#    Quando eu clicar no grupo "import_1"
#        Então eu deverei ver "Aluno 1"
#        Então eu deverei ver "Aluno 2"
#    Quando eu clicar em "Importar"
#        Então eu nao deverei ver o elemento de id "lightBoxDialog"
#        E eu deverei estar em "Lista de atividades em grupo"
#        E eu deverei ver "Grupos importados com sucesso"
#        E eu deverei ver "Atividade em grupo III"
#    Quando eu clicar no item "Atividade em grupo III" de id "6"
#        Então eu deverei aguardar "2" segundos
#        E eu deverei ver "grupo1 tI"
#            E eu deverei ver "Aluno 1"
#            E eu deverei ver "Aluno 2"
#        E eu deverei ver "grupo2 tI"
#            E eu deverei ver "Aluno 3"
#            E eu deverei ver "Usuario do Sistema"
#        E eu deverei ver "grupo3 tI"

#@javascript
#Cenário: Acessar lightbox importação de grupo e cancelar
#    Dado que estou logado com o usuario "prof" e com a senha "123456"
#        E que estou em "Meu Solar"
#    Quando eu clicar no link "Quimica I"
#        Então eu deverei ver "Atividades"
#    Quando eu clicar no link "Atividades"
#        Então eu deverei ver o link "Grupos"
#    Quando eu clicar no link "Grupos"
#        Então eu deverei ver "Atividade em grupo III"
#    Quando eu clicar no item "Atividade em grupo III" de id "import_to_6"
#        Então eu deverei ver o elemento de id "import_to_6"
#    Quando eu clicar no botao de importacao de id "6"
#        Então eu deverei aguardar "3" segundos
#        E eu deverei ver o elemento de id "lightBoxDialog"
#        E eu deverei ver o elemento de id "name_4"
#        E eu deverei ver o elemento de id "name_5"
#        E eu nao deverei ver o elemento de id "name_6"
#    Quando eu clicar no item "Atividade em grupo I" de id "import_4"
#        Então eu deverei ver "grupo1 tI"
#        E eu deverei ver "grupo2 tI"
#        E eu deverei ver "grupo3 tI"
#        E eu deverei ver o botao "Importar"
#        E eu deverei ver o botao "Cancelar"
#    Quando eu clicar em "Cancelar"
#        Então eu nao deverei ver o elemento de id "lightBoxDialog"
#        E eu deverei estar em "Lista de atividades em grupo"
#        E eu nao deverei ver "Grupos importados com sucesso"

@javascript
Cenário: Não visualizar link de grupos com usuário sem permissão
    Dado que estou logado com o usuario "aluno1" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu nao deverei ver "Grupos"

@javascript
Cenário: Tentar acessar grupos com usuário sem permissão
    Dado que estou logado com o usuario "aluno1" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu nao deverei ver "Grupos"
    Quando tento acessar "Lista de atividades em grupo"
        Então eu deverei ver "Você não tem permissão para acessar esta página"