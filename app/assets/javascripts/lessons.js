
/**
 * Código do andrei
 */

// function lessonFrameDim()
// {
//   // Esmaecendo a tela
//   dimmed_div = '<div onclick="javascript:minimize();" id="dimmed_div" name="dimmed_div" style="">&nbsp;</div>';
//   $("#lesson_external_div", parent.document.body).append(dimmed_div);
//   $("#dimmed_div", parent.document.body).fadeTo('fast', 0.4);
// }

// function change_youtube_link_to_embeded(path){
//   // recupera o texto que "equivale" ao informado, ou seja, match recuperará o caminho de um link para o youtube caso o path o seja
//   var youtube_link = (path.search("youtube") != -1 && path.search("embed") == -1);

//   if (youtube_link)
//     path = 'http://www.youtube.com/embed/' + path.split("v=")[1]; // e transformará o link padrão em um "embeded" para ser adicionado ao iframe

//   return path;
// }

/**
 * User navigation
 */

// function minimize() {
//   // Botão de exibir aula minimizada
//   var lessonsButton = $('#frame_content').contents().find('#mysolar_open_lesson button');

//   // Removendo esmaecimento
//   $("#dimmed_div").fadeOut('fast', function() { $("#dimmed_div").remove(); });

//   // Ocultando o frame da aula
//   $("#lesson_content").animate({
//     height: lessonsButton.outerHeight(),
//     width: lessonsButton.outerWidth(),
//     top: lessonsButton.offset().top,
//     left: lessonsButton.offset().left
//   },500, function(){
//     $(this).hide();
//     $(lessonsButton).removeClass("disabled");
//   });

//   // Removendo botões de minimizar e fechar
//   $("#min_button, #close_button").remove();
// }

// function maximize() {
//   if ( $("#lesson_content", parent.document.body).length != 0 ) {
//     lessonFrameDim();

//     // Exibindo a aula
//     $("#lesson_content", parent.document.body).show();
//     $("#lesson_content", parent.document.body).animate({
//       left: '1%',
//       top: '3%',
//       width: '96%',
//       height: '94%'
//     });

//     // Exibindo botoes de minimizar e fechar
//     lessonFrameButtons()
//   } else {
//     event.preventDefault();
//   }
// }

function open_lesson(obj) {
  var order = $(obj).data("order");

  $('.lesson .header .titlebar span.order').html(order);
  $("iframe#content_lesson").attr("src", $(obj).data("link"));
}
