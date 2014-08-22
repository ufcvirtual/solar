# language: pt

Funcionalidade: Exibir Agenda da oferta
  Como um usuario do solar
  Eu quero visualizar a agenda da oferta
  Para poder acessá-las

Contexto:
  Dado que tenho "allocations"
    | user_id  | allocation_tag_id  | profile_id  | status |
    | 5        | 4                  | 2           | 1      |
    | 5        | 5                  | 2           | 1      |
    | 5        | 6                  | 2           | 1      |

@javascript
Cenário: Exibir Agenda
  Dado que estou logado com o usuario "user" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "109 - Licenciatura em Quimica" em "td.course"
    Então eu deverei ver "Informações Gerais"
  Quando eu clicar no link "Agenda"
    Então eu deverei ver "Recesso"
    E eu deverei ver "Avaliação"
    E eu deverei ver "Feriado"
  Dado que eu cliquei em elemento de texto "Recesso" em "span.fc-event-title"
    Entao eu deverei ver "Evento: Recesso"
    E eu deverei ver "Licenciatura em Quimica - Quimica I - 2011.1 - QM-CAU"
    E eu deverei ver "dia todo"
    E eu deverei ver "Recesso institucional"
    E eu deverei ver o botao de link com classe "show_event"
    E eu nao deverei ver o botao de link com classe "edit_event"
    E eu nao deverei ver o botao de link com classe "delete_event"

@javascript
Cenário: Exibir Agenda do professor
  Dado que estou logado com o usuario "prof" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "110 - Letras Portugues" em "td.course"
    Entao eu deverei ver "Informações Gerais"
  Quando eu clicar no link "Agenda"
    Entao eu deverei ver "Atividade individual VII"
  # botão próximo
  Quando eu clicar no botao de icone com classe "icon-arrow-right-thin"
    Entao eu deverei ver "Forum 7"
  Dado que eu cliquei em elemento de texto "Forum 7" em "span.fc-event-title"
    Entao eu deverei ver "Fórum: Forum 7"
    E eu deverei ver "Letras Portugues - Teoria da Literatura I - 2011.1 - TL-CAU"
    E eu deverei ver "dia todo"
    E eu deverei ver "Assim mesmo, o desenvolvimento de distintas formas representa uma abertura para a melhoria dos procedimentos normalmente adotados."
    E eu deverei ver o botao de link com classe "show_event"
    E eu nao deverei ver o botao de link com classe "edit_event"
    E eu nao deverei ver o botao de link com classe "delete_event"

@javascript
Cenário: Verificar tipos de visualizacoes da agenda e botoes de navegacao
  Dado que estou logado com o usuario "prof" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "110 - Letras Portugues" em "td.course"
    Entao eu deverei ver "Informações Gerais"
  Quando eu clicar no link "Agenda"
    #E eu clicar no botao de icone com classe "icon-arrow-right-thin"
    Entao eu deverei ver "Atividade individual VII"
  Quando eu clicar no botao de icone com classe "icon-calendar-list"
    Entao eu deverei ver "Lista de eventos futuros"
    E eu deverei ver "dia todo"
    E eu deverei ver "Forum 7"
  Quando eu clicar no botao de icone com classe "icon-calendar-day"
    Entao eu devo ver a visualizacao diaria
  Quando eu clicar no botao de icone com classe "icon-calendar-week"
    Entao eu devo ver a visualizacao semanal
  Quando eu clicar no botao de icone com classe "icon-calendar-month"
    Entao eu devo ver a visualizacao mensal
  Quando eu clicar no botao de icone com classe "icon-arrow-left-thin"
    Entao eu devo ver o nome mes passado
  Quando eu clicar no botao de icone com classe "icon-arrow-right-thin"
    Entao eu devo ver o nome deste mes
  Quando eu clicar no botao de icone com classe "icon-arrow-right-thin"
    Entao eu devo ver o nome mes que vem
  Dado que eu cliquei no botao com texto "hoje"
    Entao eu devo ver o nome deste mes

@javascript
Cenário: Verificar abertura do lightbox com exibição dos detalhes
  Dado que estou logado com o usuario "prof" e com a senha "123456"
    E que estou em "Meu Solar"
  Dado que eu cliquei em elemento de texto "110 - Letras Portugues" em "td.course"
    Entao eu deverei ver "Informações Gerais"
  Quando eu clicar no link "Agenda"
    E eu clicar no botao de icone com classe "icon-arrow-right-thin"
    Entao eu deverei ver "Forum 7"
  Dado que eu cliquei em elemento de texto "Forum 7" em "span.fc-event-title"
    Entao eu deverei ver "Fórum: Forum 7"
    E eu deverei ver "Letras Portugues - Teoria da Literatura I - 2011.1 - TL-CAU"
    E eu deverei ver "dia todo"
    E eu deverei ver "Assim mesmo, o desenvolvimento de distintas formas representa uma abertura para a melhoria dos procedimentos normalmente adotados."
    E eu deverei ver o botao de link com classe "show_event"
    Dado que eu cliquei em ".show_event"
      Entao eu deverei ver "Detalhes do fórum"
      E eu deverei ver "Nome"
      E eu deverei ver "Descrição"
      E eu deverei ver "Início"
      E eu deverei ver "Término"
      E eu deverei ver "Turmas"