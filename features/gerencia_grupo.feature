# language: pt
Funcionalidade: Exibir Página de Grupos de Portfolio
  Como um usuário do solar
  Eu quero listar os trabalhos de grupo disponíveis
  Para poder gerenciar os grupos de trabalho

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 3                  | 3           | 1      |

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

@javascript
Cenário: Exibir Grupos de Trabalho
    Dado que estou logado com o usuario "prof" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Grupos"
    Quando eu clicar no link "Grupos"
        Então eu deverei ver "Atividade em grupo I"
        Então eu deverei ver "Atividade em grupo II"
    Quando eu clicar no item "Atividade em grupo I"
        Então eu deverei ver "grupo1 tI"
        E eu deverei ver "grupo2 tI"
        E eu deverei ver "grupo3 tI"
    Quando eu clicar no item "Atividade em grupo II"
        Então eu deverei ver "grupo1 - tII"
        E eu deverei ver "grupo2 - tII"

@javascript 
Cenário: Acessar página de cadastro de novo grupo
    Dado que estou logado com o usuario "prof" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Grupos"
    Quando eu clicar no link "Grupos"
        Então eu deverei ver "Atividade em grupo I"
        Então eu deverei ver "Atividade em grupo II"
    Quando eu clicar no item "Atividade em grupo I"
        Então eu deverei ver "grupo1 tI"
        E eu deverei ver "grupo2 tI"
        E eu deverei ver "grupo3 tI"
        E eu deverei ver o botao "Novo grupo"
    Quando eu clicar em "Novo grupo"
        Então eu deverei ver "Grupos da atividade Atividade em grupo I"
        Então eu deverei ver "grupo1 tI"
            E eu deverei ver "Aluno 1"
            E eu deverei ver "Aluno 2"
        E eu deverei ver "grupo2 tI"
            E eu deverei ver "Aluno 3"
            E eu deverei ver "Usuario do Sistema"
        E eu deverei ver "grupo3 tI"
            E eu deverei ver "Grupo sem participantes"
        E eu deverei ver "Novo grupo"    
            E eu deverei ver "Nome do grupo"
            E eu deverei ver "Alunos"

@javascript 
Cenário: Cadastro de novo grupo
    Dado que estou logado com o usuario "prof" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Grupos"
    Quando eu clicar no link "Grupos"
        Então eu deverei ver "Atividade em grupo I"
    Quando eu clicar no item "Atividade em grupo I"
        E eu deverei ver o botao "Novo grupo"
    Quando eu clicar em "Novo grupo"
        Dado que eu preenchi "group_assignment_group_name" com "grupo100 tI"
        Então eu deverei ver o botao "Salvar"
            E eu deverei ver o botao "Cancelar"
        Quando eu clicar em "Salvar"
            Então eu deverei ver "Grupo salvo com sucesso"

@javascript
Cenário: Acessar página de edição de grupo
    Dado que estou logado com o usuario "prof" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Grupos"
    Quando eu clicar no link "Grupos"
        Então eu deverei ver "Atividade em grupo I"
    Quando eu clicar no item "Atividade em grupo I"
        Então eu deverei ver "grupo1 tI"
            E eu deverei ver o link "Editar"
    Quando eu clico no link "Editar"
        Então eu deverei ver "Grupos da atividade Atividade em grupo I"
            Então eu deverei ver "Editar grupo"
                E eu deverei ver "Nome do grupo"
                E eu deverei ver "Alunos"

@javascript  @wip
Cenário: Edição de grupo
    Dado que estou logado com o usuario "prof" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Grupos"
    Quando eu clicar no link "Grupos"
        Então eu deverei ver "Atividade em grupo I"
    Quando eu clicar no item "Atividade em grupo I"
        Então eu deverei ver "grupo1 tI"
            E eu deverei ver o link "Editar"
    Quando eu clico no link "Editar"
        Dado que eu preenchi "group_assignment_group_name" com "grupo1.2 tI"
            E que eu cliquei no grupo "2"
        Então eu deverei ver "Aluno 3"
            E eu deverei ver "Usuario do sistema"
        Quando eu selecionar o usuario de id "2"
            Então eu deverei ver o botao "Salvar"
                E eu deverei ver o botao "Cancelar"
            Quando eu clicar em "Salvar"
                Então eu deverei ver "Grupo salvo com sucesso"
        

#Cenário: Acessar página de cadastro de novo usuário
#    Dado que eu nao estou cadastrado
#        E que estou em "Login"
#                E eu clico no link "Cadastrar"
#    Então eu deverei ver "Login"
#        E eu deverei ver "Senha"
#        E eu deverei ver "Confirmação da senha"
#        E eu deverei ver "Apelido"
#        E eu deverei ver "E-mail"
#        E eu deverei ver o botao "Confirmar"

#@javascript
#Cenário: Cadastrar novo usuário
#    Dado que estou em "Cadastrar usuario"
#       E que eu preenchi "username" com "usuario"
#       E que eu preenchi "password" com "123456"
#       E que eu preenchi "password_confirmation" com "123456"
#    Quando eu clicar em "Confirmar"
#    Então eu deverei visualizar "Sair"
#        E eu deverei visualizar "Home"

#Cenário: Cadastrar novo usuário com dados inválidos
#    Dado que estou em "Cadastrar usuario"
#       E que eu preenchi "username" com ""
#       E que eu preenchi "password" com "123456"
#       E que eu preenchi "password_confirmation" com "123456"
#    Quando eu clicar em "Confirmar"
#    Então eu deverei ver "Login é muito curto(a) (mínimo: 3 caracteres)"