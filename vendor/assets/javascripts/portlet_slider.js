$(function(){

  /* Slider: exibir/ocultar qualquer conteúdo do slide sobrepondo o conteúdo padrão */
  $(".slider-block").click(function(){
    $(".slide.slide-block").toggle("slide", {direction: "right"});
  });

  /* Slider: exibir/ocultar barra lateral de configurações empurrando o conteúdo padrão */
  var sliderSettings = $(".slider-settings");
  $(sliderSettings).click(function(){
    var slideMain = $(this).parents(".block_to_slide").find(".slide-main"),
    settingsSlide = $(this).parents(".block_to_slide").find(".slide-settings"),
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

});
