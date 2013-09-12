//Novo post - mostrar e ocultar a caixa de texto
$(function(){
  $(".new_post_button").click(function () {
    if ($(".new_post").is(":hidden")) {
      $(".new_post").slideDown("slow");
    } else {
      $(".new_post").slideUp("slow");
    }
  });
});