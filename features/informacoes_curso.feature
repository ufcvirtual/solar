# language: pt
Funcionalidade: Exibir informacoes do curso
  Como um usuario do solar
  Eu quero acessar as informacoes basicas do curso

Contexto:
    Dado que tenho "offers"
        | id | curriculum_units_id | courses_id | semester | start      | end        |
        | 1  | 1                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 2  | 2                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 3  | 3                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 4  | 4                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
        | 5  | 5                   |            | 2011.1   | 2011-06-01 | 2021-12-01 |
    Dado que tenho "groups"
        | id | offers_id | code  | status |
        | 1  | 1         | FOR   | TRUE   |
        | 2  | 2         | CAU-A | TRUE   |
        | 3  | 3         | CAU-B | TRUE   |
        | 4  | 4         | FOR   | TRUE   |
        | 5  | 5         | FOR   | TRUE   |
    Dado que tenho "allocation_tags"
        | id |  offers_id |
        | 1  |  1         |
    Dado que tenho "allocations"
        | users_id | allocation_tags_id | profiles_id | status |
        | 1        | 1                  | 3           | 1      |
        | 2        | 1                  | 2           | 1      |

Cenário: Acessar pagina de informacoes do curso
    Dado que estou logado com o usuario "user" e com a senha "user123"
        E que estou em "Meu Solar"
        Quando eu clicar em "Introducao a Linguistica"
        Então eu deverei ver "Informacoes"
    Quando eu clicar no link "Informacoes"
        Então eu deverei ver "Ementa"
        E eu deverei ver "Como Deleuze eloquentemente mostrou, o inicio da atividade geral de formacao de conceitos obstaculiza a apreciacao da importancia dos paradigmas filosoficos."
        E eu deverei ver "Objetivos"
        E eu deverei ver "Do mesmo modo, a indeterminao contnua de distintas formas de fenmeno..."
        E eu deverei ver "Pré-requisitos"
        E eu deverei ver "Todavia, a consolidacao das estruturas psico-lgicas assume..."
        E eu deverei ver "Resumo"
        E eu deverei ver "Pensando mais a longo prazo, a percepo das dificuldades nao causa impacto indireto na reavaliacao da formula da ressonancia racionalista."
        E eu deverei ver "Período"
        E eu deverei ver "01/06/2011 - 01/12/2021"
        E eu deverei ver "Média"
        E eu deverei ver "7"
        E eu deverei ver "Responsáveis"
        E eu deverei ver "Ricardo Palacio (Prof. Titular)"
        E eu deverei ver "Usuario Sobrenome (Tutor)"
