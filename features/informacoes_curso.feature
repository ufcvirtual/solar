# language: pt
Funcionalidade: Exibir informacoes do curso
  Como um usuario do solar
  Eu quero acessar as informacoes basicas do curso

Contexto:
    Dado que tenho "allocations"
        | user_id  | allocation_tag_id  | profile_id  | status |
        | 1        | 1                  | 3           | 1      |
        | 2        | 1                  | 2           | 1      |
        | 1        |                    | 12          | 1      |
        | 2        |                    | 12          | 1      |

Cenário: Acessar pagina de informacoes do curso
    Dado que estou logado com o usuario "user" e com a senha "123456"
        E que estou em "Meu Solar"
        Quando eu clicar no link "Introducao a Linguistica"
        Então eu deverei ver "Informações Gerais"
    Quando eu clicar no link "Informações Gerais"
        Então eu deverei ver "Programa"
    Quando eu clicar no link "Programa"
        Então eu deverei ver "Ementa"
        E eu deverei ver "Como Deleuze eloquentemente mostrou, o inicio da atividade geral de formacao de conceitos obstaculiza a apreciacao da importancia dos paradigmas filosoficos."
        E eu deverei ver "Objetivos"
        E eu deverei ver "Do mesmo modo, a indeterminao contnua de distintas formas de fenmeno..."
        E eu deverei ver "Pré-requisitos"
        E eu deverei ver "Todavia, a consolidacao das estruturas psico-lgicas assume..."
        E eu deverei ver "Resumo"
        E eu deverei ver "Pensando mais a longo prazo, a percepo das dificuldades nao causa impacto indireto na reavaliacao da formula da ressonancia racionalista."
        E eu deverei ver "Período"
        E eu deverei ver "10/03/2011 - 01/12/2021"
        E eu deverei ver "Média"
        E eu deverei ver "7"
        E eu deverei ver "Responsáveis"
        E eu deverei ver "Ricardo Palacio (Prof. Titular)"
        E eu deverei ver "Usuario do Sistema (Tutor a Distancia)"
