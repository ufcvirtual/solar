$(document).ready(function(){

  /* Slider: exibir/ocultar barra lateral de configurações */
  var sliderSettings = $(".slider-settings");
  $(sliderSettings).click(function(){
    var slideMain = $(this).parents(".block_facebook").find(".slide-main"),
    settingsSlide = $(this).parents(".block_facebook").find(".slide-settings"),
    settingsWidth = $(settingsSlide).outerWidth(),
    settingsStatus = $(settingsSlide).data("status");
    if ( settingsStatus === "closed" ) {
      unit = "-=";
      $(settingsSlide).data("status","opened");
    } else {
      unit = "+=";
      $(settingsSlide).data("status","closed");
    }
    slideMain.animate({
      'left':unit+settingsWidth
    });
  });

  /* Novo post: aumentar tamanho do areatext e exibir barra de postagem */
  $(".block_facebook textarea").focus(function(){
    $(this).addClass("active");
    $(this).parent().find(".new_post_bar").slideToggle("slow");
  });
  $(".block_facebook textarea").focusout(function(){
    $(this).removeClass("active");
    $(this).parent().find(".new_post_bar").slideToggle("slow");
  });

  /* Comentários: adicionar campo de texto ao clicar em comentários */
  var teste = "<div class='new_comment' style='display: none'><textarea type='text' placeholder='Novo comentário' style='width: 95%; border: none'></textarea><div class='new_post_bar' style='display: block'><button class='cancel'>Cancelar</button><button>Publicar</button></div></div>";
  $(".post_content a.comment").click(function(event){
    event.preventDefault();
    console.info("ok");
    post = $(this).parent().parent().parent();
    console.info(post);
    $(post).append(teste);
    // $(post).find(".new_post_bar").show();
    $(post).find(".new_comment").slideDown('slow', function(){
      $(this).focus();
    });
  });
});

/*Voltar para news feed quando clicar em algun grupo */
$(document).ready(function() {
  $('.commondark a, .info a').click(function(){
    $('.slider-settings').click();
  });
});