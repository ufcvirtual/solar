# language: pt

Funcionalidade: Exibir Portfolio
  Como um usuario do solar
  Eu quero visualizar o portfolio
  Para poder acessá-los
Cenário: Exibir Portfolio e atividades individuais como aluno
    Dado que estou logado com o usuario "aluno1" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Portfolio"
    Quando eu clicar no link "Portfolio"
        Então eu deverei ver "Portfolio"
        E eu deverei ver "Atividades individuais"
        E eu deverei ver "Descrição"
        E eu deverei ver o link "Atividade III"
        # FIXME: as datas das atividades II, III e atividade individual VI, VI, V, I estão com diferença de 2 dias em relação ao que é visualizado, não sei por que
        E eu deverei ver os seguintes dados na tabela "#assignment_individual":
            | Descrição                 | Período                 | Situação     | Nota           | Comentários |
            | Atividade individual VI   | 13/08/2011 17/09/2011   | Não Enviado  | -              |             |
            | Atividade II              | 03/08/2014 03/12/2014   | Não Iniciado | -              |             |
            | Atividade III             | 03/05/2014 03/08/2014   | Corrigido    | 6.3            |             |
            | Atividade individual VII  | 01/07/2014 02/07/2014   | Enviado      | -              |             |
            | Atividade individual IV   | 03/08/2014 03/12/2014   | Não Iniciado | -              |             |
            | Atividade individual V    | 03/05/2014 03/08/2014   | Enviado      | -              |             |
            | Atividade I               | 03/05/2014 03/08/2014   | Enviar       | -              |             |
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

Cenário: Exibir Listagem de Atividades Individuais de Portifólio como Professor
Dado que estou logado com o usuario "prof" e com a senha "123456"
        E que estou em "Meu Solar"
    Quando eu clicar no link "Quimica I"
        Então eu deverei ver "Atividades"
    Quando eu clicar no link "Atividades"
        Então eu deverei ver o link "Portfolio"
    Quando eu clicar no link "Portfolio"
        Então eu deverei ver "Portfolio"
        E eu deverei ver "Atividades individuais"
        E eu deverei ver "Descrição"
        E eu deverei ver o link "Atividade III"
        # FIXME: as datas das atividades II, III e atividade individual VI, VI, V, I estão com diferença de 2 dias em relação ao que é visualizado, não sei por que
        E eu deverei ver os seguintes dados na tabela "#assignment_individual":
            | Descrição                 | Período                   |
            | Atividade individual VI   | 13/08/2011 - 17/09/2011   |
            | Atividade I               | 03/05/2014 - 03/08/2014   |
            | Atividade III             | 03/05/2014 - 03/08/2014   |
            | Atividade individual V    | 03/05/2014 - 03/08/2014   |
            | Atividade individual VII  | 01/07/2014 - 02/07/2014   |
            | Atividade individual IV   | 03/08/2014 - 03/12/2014   |
            | Atividade II              | 03/08/2014 - 03/12/2014   |
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
