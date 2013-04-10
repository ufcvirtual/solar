# language: pt

Funcionalidade: Exibir Portfolio
  Como um usuario do solar
  Eu quero visualizar o portfolio
  Para poder acessá-los

Cenário: Exibir Portfolio
    Dado que estou logado com o usuario "user" e com a senha "123456"
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
    Quando eu clicar no link "Atividade III"
        Então eu deverei ver "Atividade III"
            E eu deverei ver "Descrição"
                E eu deverei ver "Podemos já vislumbrar o modo pelo qual a crescente influência"
        E eu deverei ver "Arquivos da atividade"
            E eu deverei ver "Sem itens para exibir"
        E eu deverei ver "Arquivos enviados"
            E eu deverei ver "Sem itens para exibir"
        E eu deverei ver "Comentários"
            E eu deverei ver "Sem itens para exibir"


#Cenário: Enviar arquivo
#Cenário: Deletar arquivo
#Cenário: Como aluno, baixar arquivo da área publica de um aluno da mesma turma
#Cenário: Como aluno, tentar baixar arquivo da área publica de um aluno de outra turma
#Cenário: Como responsável, Tentar baixar arquivo da área publica de um aluno de outra turma
#Cenário: Estando alocado em oferta, tentar baixar arquivo da área publica de aluno de alguma turma relacionada
#Cenário: Estando alocado em Unidade Curricular, tentar baixar arquivo da área publica de aluno de alguma turma relacionada
#Cenário: Estando alocado em Curso, tentar baixar arquivo da área publica de aluno de alguma turma relacionada
