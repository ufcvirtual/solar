#language: pt

Funcionalidade: Aceitar Matriculas
  Como um usuário do solar com perfil de editor
  Eu quero aceitar ou recusar pedidos de matrícula para uma determinada oferta

Contexto:
  Dado que tenho "allocations"
    | user_id  | allocation_tag_id  | profile_id  | status |
    | 7        | 8                  | 1           | 0      |
    # Aluno 2 - cancelado
    | 8        | 8                  | 1           | 2      |
    # Aluno 3 - rejeitado
    | 9        | 8                  | 1           | 4      |

Cenário: Acessar pagina de matriculas solicitadas
  Dado que estou logado com o usuario "coorddisc" e com a senha "123456"
    E que estou em "Meu Solar"
    Então eu deverei ver "Unidade Curricular"
    Quando eu clicar no link "Unidade Curricular"
      Então eu deverei ver "Gerenciar Matrículas"
    Quando eu clicar no link "Gerenciar Matrículas"
      Então eu deverei ver "Matrículas Solicitadas"
      E eu deverei ver "Aluno 1"
      E eu deverei ver "Pendente"
      E eu deverei ver "Aluno 2"
      E eu deverei ver "Cancelado"
      E eu deverei ver "Aluno 3"
      E eu deverei ver "Rejeitado"
