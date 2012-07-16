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
    // ***


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
    $("#lesson_name").html(decodeURI(name));
    window.parent.frame_lesson_content.location.href = path;

    $("#mov_atual").html(mov_atual);
    move(0);
}
  
function minimize() {
    //Removendo esmaecimento
    $("#dimmed_div").fadeOut('fast', function() { $("#dimmed_div").remove(); });

    //Ocultando o frame da aula
    $("#lesson_content").fadeTo('fast', 0.0, function() { $("#lesson_content").css('display', 'none'); });

    //Exibindo a abinha minimizada
    min_tab = '<div onclick="javascript:maximize();" id="min_tab" name="min_tab"><div id="close_tab_button" >&nbsp;</div>&nbsp;&nbsp; <b>Aula</b></div>';

    $("#min_button").remove();
    $("#close_button").remove();

    $("#lesson_external_div").append(min_tab);
    $("#min_tab").slideDown('fast');

    $("#close_tab_button").click(function(event) {
        close_lesson();
        event.stopPropagation();
    });
}

function maximize() {
    //Esmaecendo a tela
    dimmed_div = '<div onclick="javascript:minimize();" id="dimmed_div" name="dimmed_div" style="">&nbsp;</div>';
    $("#lesson_external_div").append(dimmed_div);
    $("#dimmed_div").fadeTo('fast', 0.8);

    //Exibindo a aula
    $("#lesson_content").fadeTo('fast', 1.0);

    //Botões de minimizar e fechar
    minButton = '<div onclick="javascript:minimize();" id="min_button">&nbsp;</div>';
    closeButton = '<div onclick="javascript:close_lesson();" id="close_button">&nbsp;</div>';

    $("#lesson_external_div").append(closeButton);
    $("#lesson_external_div").append(minButton);

    //Removendo a aba minimizada
    $("#min_tab").slideUp('fast', function() { $("#min_tab").remove(); });
}

function show_lesson(path) {

    //Esmaecendo a tela
    dimmed_div = '<div onclick="javascript:minimize();" id="dimmed_div" name="dimmed_div">&nbsp;</div>';
    $("#lesson_external_div", parent.document.body).append(dimmed_div);
    $("#dimmed_div", parent.document.body).fadeTo('fast', 0.8);

    $("#lesson_content", parent.document.body).remove();
    lessonh = "<div id=lesson_content></div>";
    $("#lesson_external_div", parent.document.body).append(lessonh);

    lesson = '<iframe id="lessonf" name="lessonf" src="' + path + '"></iframe>';

    //Exibindo a aula
    $("#lessonf", parent.document.body).remove();
    $("#lesson_content", parent.document.body).append(lesson);
    
    setTimeout('$("#lesson_content",parent.document.body).slideDown("fast");', 500);

    //Exibindo botoes de minimizar e fechar
    minButton = '<div onclick="javascript:minimize();" id="min_button">&nbsp;</div>';
    closeButton = '<div onclick="javascript:close_lesson();" id="close_button">&nbsp;</div>';
    $("#lesson_external_div", parent.document.body).append(closeButton);
    $("#lesson_external_div", parent.document.body).append(minButton);

    //Removendo a aba minimizada, se ela estiver aparecendo
    $("#min_tab", parent.document.body).slideUp('fast', function() {$("#min_tab", parent.document.body).remove();});
}

function close_lesson() {
    //Removendo esmaecimento
    $("#dimmed_div").fadeOut('fast', function() {$("#dimmed_div").remove();});

    //Ocultando o frame da aula
    $("#lesson_content").fadeTo('fast', 0.0, function() {$("#lesson_content").remove();});

    $("#min_button").remove();
    $("#close_button").remove();

    $("#lesson_external_div").append(min_tab);
    $("#min_tab").slideDown('fast');

    //Removendo a aba minimizada, se ela estiver aparecendo
    $("#min_tab").slideUp('fast', function() {$("#min_tab").remove();});
}

function clear_lesson() {
    $("#min_tab", parent.document.body).remove();
    $("#lesson_content", parent.document.body).remove();
    $("#dimmed_div", parent.document.body).remove();
    $("#min_button", parent.document.body).remove();
    $("#close_button", parent.document.body).remove();
}
