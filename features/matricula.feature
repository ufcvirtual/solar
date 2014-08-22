# language: pt

Funcionalidade: Exibir tela de matricula
  Como um usuário do solar
  Eu quero acessar a listagem de unidades curriculares
  Para verificar e alterar matricula

@javascript
Cenário: Acessar página de matricula
  Dado que estou logado com o usuario "user" e com a senha "123456"
  Quando eu clicar no link de conteudo "Matrícula"
  Então eu deverei visualizar "Matrícula"
    E eu deverei visualizar "Disciplina"
    E eu deverei visualizar "Categoria"
    E eu deverei visualizar "Turma"
    E eu deverei visualizar "Buscar"

@javascript
Cenário: Listar cursos matriculados ou disponíveis
  Dado que estou logado com o usuario "user" e com a senha "123456"
  Quando eu clicar no link de conteudo "Matrícula"
  Então eu deverei visualizar a linha de opcao de matricula
    | Disciplina                    | Categoria                           | Turma   | Matricula       |
    | Introducao a Linguistica      | Curso Livre                         | IL-FOR  | Cancelar        |
    | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial   | LB-CAR  | Cancelar pedido |
    | Quimica I                     | Curso de Graduacao a Distancia      | QM-CAU  | Cancelar        |
    | Teoria da Literatura I        | Curso de Graduacao Presencial       | TL-CAU  | Matricular      |
  E eu nao deverei visualizar a linha de opcao de matricula
    | Disciplina                    | Categoria                           | Turma   | Matricula   |
    | Semipresencial sm nvista      | Curso de Pos-Graduacao a Distancia  | SP-FOR  | Matricular  |
    | Teoria da Literatura I        | Curso de Graduacao Presencial       | SP-CAU  | Matricular  |
    # A última linha a não ser apresentada faz referência à uma oferta cujo período de matrícula tem fim indefinido e data final da oferta anterior ao dia atual

Cenário: Pedir cancelamento de matricula
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Matricula"
  Quando eu clicar na opcao "Cancelar" do item de matricula "Introducao a Linguistica" do semestre "2011.1"
  Então eu deverei ver a linha de opcao de matricula
    | Disciplina                    | Categoria                           | Turma   | Matricula       |
    | Introducao a Linguistica      | Curso Livre                         | IL-FOR  | Matricular      |
    | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial   | LB-CAR  | Cancelar pedido |
    | Quimica I                     | Curso de Graduacao a Distancia      | QM-CAU  | Matriculado     |
    | Teoria da Literatura I        | Curso de Graduacao Presencial       | TL-CAU  | Matricular      |

Cenário: Pedir matricula em curso disponível
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Matricula"
  Quando eu clicar na opcao "Matricular" do item de matricula "Teoria da Literatura I" do semestre "2011.1"
  Então eu deverei ver a linha de opcao de matricula
    | UnidadeCurricular             | Categoria                           | Turma   | Matricula       |
    | Introducao a Linguistica      | Curso Livre                         | IL-FOR  | Cancelar        |
    | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial   | LB-CAR  | Cancelar pedido |
    | Quimica I                     | Curso de Graduacao a Distancia      | QM-CAU  | Matriculado     |
    | Teoria da Literatura I        | Curso de Graduacao Presencial       | TL-CAU  | Cancelar pedido |

Cenário: Cancelar pedido de matricula
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Matricula"
  Quando eu clicar na opcao "Cancelar pedido" do item de matricula "Literatura Brasileira I" do semestre "2011.1"
  Então eu deverei ver a linha de opcao de matricula
    | UnidadeCurricular             | Categoria                           | Turma   | Matricula       |
    | Introducao a Linguistica      | Curso Livre                         | IL-FOR  | Cancelar        |
    | Quimica I                     | Curso de Graduacao a Distancia      | QM-CAU  | Matriculado     |
    | Teoria da Literatura I        | Curso de Graduacao Presencial       | TL-CAU  | Matricular      |
  E eu nao deverei ver a linha de opcao de matricula
    | Literatura Brasileira I       | Curso de Pos-Graduacao Presencial   | LB-CAR  | Matricular      |
    # Após a última ação, usuário não vê mais Literatura Brasileira I pois o período de matrícula expirou. 
    # Ela só era exibida antes, pois o usuário tinha "vínculo" com ela. Como ele "quebrou" o vínculo (cancelou pedido), não há motivo para ela ficar visível.