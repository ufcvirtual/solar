function move(direction) {
  var mov_atual = $("#mov_atual").html();
  var total = $("#total_lesson").html();

  // *** so habilita movimentacao se qtde de aulas for maior que espaco para listagem
  var width  = parseFloat($(".lesson_link").css("width"));
  var margin = parseFloat($(".lesson_link").css("margin-right"));
  var width_atual = (width+margin)*total;
  var width_max   = parseInt($("#content-scroll").css("width"));

  //se eh menor nao precisa de navegacao - remove visibilidade e retorna
  if ( width_atual < width_max ){
    $("#link_lesson_back").removeClass("lesson_back").addClass("invisible");
    $("#link_lesson_next").removeClass("lesson_next").addClass("invisible");
    mov_atual=1;
    direction=0;
  }
  else {
    $("#link_lesson_back").removeClass("invisible").addClass("lesson_back");
    $("#link_lesson_next").removeClass("invisible").addClass("lesson_next");
  }

  //direction:
  //    1: pra tras
  //    2: pra frente

  if (direction==2){
    if (mov_atual<total)
      mov_atual++;
  }
  else {
    if (direction==1){
      if (mov_atual>=1)
        mov_atual--;
    }
  }

  //atualiza valor
  $("#mov_atual").html(mov_atual);

  //atualiza para exibicao (mostra antes do clicado)
  if (mov_atual>0)
    mov_atual--;

  //calcula deslocamento
  var scroll = (mov_atual)*18;

  $("#content-scroll").animate({scrollLeft: scroll + 'px'}, 50);
}

function goto_lesson() {
  lesson_selected = $("#lesson_text_goto").val();

  //clica no link da aula desejada
  element = "lesson_link"+lesson_selected;

  $("#"+element).trigger('click');

  if ($("#"+element).length>0) {
    $("#mov_atual").html(lesson_selected);
    move(0);
  }
}

function reload_frame(path,name,mov_atual) {
  path = change_youtube_link_to_embeded(path);

  $("#lesson_name").html(decodeURI(name));
  window.parent.frame_lesson_content.location.href = path;
  
  $("#mov_atual").html(mov_atual);
  move(0);
}

function lessonFrameButtons()
{
  //Exibindo botoes de minimizar e fechar
  minButton = '<div onclick="javascript:minimize();" id="min_button">&nbsp;</div>';
  closeButton = '<div onclick="javascript:close_lesson();" id="close_button">&nbsp;</div>';
  $("#lesson_external_div", parent.document.body).append(closeButton);
  $("#lesson_external_div", parent.document.body).append(minButton);
}

function lessonFrameDim()
{
  // Esmaecendo a tela
  dimmed_div = '<div onclick="javascript:minimize();" id="dimmed_div" name="dimmed_div" style="">&nbsp;</div>';
  $("#lesson_external_div", parent.document.body).append(dimmed_div);
  $("#dimmed_div", parent.document.body).fadeTo('fast', 0.4);
}

function lessonFrameContent(path)
{
  $("#lesson_content", parent.document.body).remove();
  lessonh = "<div id=lesson_content></div>";
  $("#lesson_external_div", parent.document.body).append(lessonh);

  lesson = '<iframe id="lessonf" name="lessonf" src="' + path + '"></iframe>';

  //Exibindo a aula
  $("#lessonf", parent.document.body).remove();
  $("#lesson_content", parent.document.body).append(lesson);
}


function minimize() {
  
  // Botão de exibir aula minimizada
  var lessonsButton = $('#frame_content').contents().find('#mysolar_lessons button');

  // Removendo esmaecimento
  $("#dimmed_div").fadeOut('fast', function() { $("#dimmed_div").remove(); });

  // Ocultando o frame da aula
  $("#lesson_content").animate(
  {
      height: lessonsButton.outerHeight(),
      width: lessonsButton.outerWidth(),
      top: lessonsButton.offset().top,
      left: lessonsButton.offset().left
  },500, function(){
      $(this).hide();
      $(lessonsButton).removeClass("disabled");
  });

  // Removendo botões de minimizar e fechar
  $("#min_button, #close_button").remove();
}

function maximize() {
  if ( $("#lesson_content", parent.document.body).length != 0 ) {
    lessonFrameDim();

    // Exibindo a aula
    $("#lesson_content", parent.document.body).show();
    $("#lesson_content", parent.document.body).animate(
      {
        left: '1%',
        top: '3%',
        width: '96%',
        height: '94%'
      });

    // Exibindo botoes de minimizar e fechar
    lessonFrameButtons()
  } else {
    event.preventDefault();
  }
  
}

function show_lesson(path) {
  document.cookie = "open_lesson="+path+"; path=/"
  alert( document.cookie );

  lessonFrameDim();

  lessonFrameContent(path);
  
  setTimeout('$("#lesson_content",parent.document.body).slideDown("fast");', 5);

  // Exibindo botoes de minimizar e fechar
  lessonFrameButtons();

  // Ativar botão de exibir aula minimizada
  var lessonsButton = $('#frame_content').contents().find('#mysolar_lessons button');
  $(lessonsButton).removeClass("disabled");
}

function close_lesson() {
  // Botão de exibir aula minimizada
  var lessonsButton = $('#frame_content').contents().find('#mysolar_lessons');

  // Desabilitando botão
  $("button", lessonsButton).addClass("disabled");

  //Removendo esmaecimento
  $("#dimmed_div").fadeOut('fast', function() {$("#dimmed_div").remove();});

  //Ocultando o frame da aula
  $("#lesson_content").fadeOut('fast', function() {$("#lesson_content").remove();});

  $("#min_button, #close_button").remove();
}

function clear_lesson() {
  $("#lesson_content, #dimmed_div, #min_button, #close_button", parent.document.body).remove();
}

function change_youtube_link_to_embeded(path){
  // recupera o texto que "equivale" ao informado, ou seja, match recuperará o caminho de um link para o youtube caso o path o seja
  var youtube_link = (path.search("youtube") != -1 && path.search("embed") == -1);

  if (youtube_link)
    path = 'http://www.youtube.com/embed/' + path.split("v=")[1]; // e transformará o link padrão em um "embeded" para ser adicionado ao iframe

  return path;
}