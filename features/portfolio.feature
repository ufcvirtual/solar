# language: pt

Funcionalidade: Exibir Portfolio
  Como um usuario do solar
  Eu quero visualizar o portfolio
  Para poder acessá-los

@javascript
Cenário: Exibir Portfolio e Atividades Individuais como Aluno
    Dado que estou logado com o usuario "aluno1" e com a senha "123456"
        E que estou em "Meu Solar"
    Dado que eu cliquei em elemento de texto "109 - Licenciatura em Quimica" em "td.course"
        Então eu deverei ver "Portfolio"
    Quando eu clicar no link "Portfolio"
        Então eu deverei ver "Portfolio"
        E eu deverei ver "Atividades individuais"
        E eu deverei ver "Descrição"
        E eu deverei ver o link "Atividade III"
        E eu deverei ver os seguintes dados na tabela "#assignment_individual" como aluno:
            | Descrição                 | Período                                     | Situação     | Nota           | Comentários |
            | Atividade individual VI   | 13/08/2011 17/09/2011                       | Não Enviado  | -              |             |
            | Atividade II              | Date.today >> 1 ; Date.today >> 5           | Não Iniciado | -              |             |
            | Atividade III             | Date.today << 2 ; Date.today >> 1           | Corrigido    | 6.3            |             |
            | Atividade individual VII  | Date.today - 2.days ; Date.today - 1.days   | Enviado      | -              |             |
            | Atividade individual IV   | Date.today >> 1 ; Date.today >> 5           | Não Iniciado | -              |             |
            | Atividade individual V    | Date.today << 2 ; Date.today >> 1           | Enviado      | -              |             |
            | Atividade I               | Date.today << 2 ; Date.today >> 1           | Enviar       | -              |             |
    Quando eu clicar no link "Atividade III"
        Então eu deverei ver "Atividade III"
            E eu deverei ver "Descrição"
                E eu deverei ver "Podemos já vislumbrar o modo pelo qual a crescente influência"
            E eu deverei ver "Descrição"
        E eu deverei ver "Arquivos da atividade"
            E eu deverei ver "Sem itens para exibir"
        E eu deverei ver "Arquivos enviados"
            E eu deverei ver "Sem itens para exibir"
        E eu deverei ver "Comentários"
            E eu deverei ver "Sem itens para exibir"

@javascript
Cenário: Exibir Listagem de Atividades Individuais de Portifólio como Professor
Dado que estou logado com o usuario "prof" e com a senha "123456"
        E que estou em "Meu Solar"
    Dado que eu cliquei em elemento de texto "109 - Licenciatura em Quimica" em "td.course"
        Então eu deverei ver "Portfolio"
    Quando eu clicar no link "Portfolio"
        Então eu deverei ver "Portfolio"
        E eu deverei ver "Atividades individuais"
        E eu deverei ver "Descrição"
        E eu deverei ver o link "Atividade III"
        E eu deverei ver os seguintes dados na tabela "#assignment_individual" como professor:
            | Descrição                 | Período                                   |
            | Atividade individual VI   | 13/08/2011 - 17/09/2011                   |
            | Atividade I               | Date.today << 2 ; Date.today >> 1         |
            | Atividade III             | Date.today << 2 ; Date.today >> 1         |
            | Atividade individual V    | Date.today << 2 ; Date.today >> 1         |
            | Atividade individual VII  | Date.today - 2.days ; Date.today - 1.days |
            | Atividade individual IV   | Date.today >> 1 ; Date.today >> 5         |
            | Atividade II              | Date.today >> 1 ; Date.today >> 5         |
    Quando eu clicar no link "Atividade III"
        Então eu deverei ver "Atividade III"
            E eu deverei ver "Descrição"
                E eu deverei ver "Podemos já vislumbrar o modo pelo qual a crescente influência"
        E eu deverei ver "Arquivos da atividade"
            E eu deverei ver "Sem itens para exibir"

#Cenário: Exibir Informações de Atividade de Portifólio como Professor
#Cenário: Exibir Atividade de Portifólio de um aluno como Professor
# Página não tem informação de nome de aluno. Colocar essa informação no teste e corrigir na página

#Cenário: Enviar arquivo
#Cenário: Deletar arquivo
#Cenário: Como aluno, baixar arquivo da área publica de um aluno da mesma turma
#Cenário: Como aluno, tentar baixar arquivo da área publica de um aluno de outra turma
#Cenário: Como responsável, Tentar baixar arquivo da área publica de um aluno de outra turma
#Cenário: Estando alocado em oferta, tentar baixar arquivo da área publica de aluno de alguma turma relacionada
#Cenário: Estando alocado em Unidade Curricular, tentar baixar arquivo da área publica de aluno de alguma turma relacionada
#Cenário: Estando alocado em Curso, tentar baixar arquivo da área publica de aluno de alguma turma relacionada
