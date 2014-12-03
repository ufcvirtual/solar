$(function(){
  /* script dos paineis de informacao */
  $(".panel .arrow").click(function() {
      $(".menu_footer a").removeClass("current_menu");
      $(".panel").fadeOut();
  });
  $(".panel-link").click(function(event) {
      event.preventDefault();
      var painelId = $(this).attr("href");
      $(".panel-link").removeClass("current_menu");
      $("a[href=" + painelId + "]").addClass("current_menu");
      if ($(painelId).css("display") == "block") {
          $(painelId).fadeOut(800);
          $("a[href=" + painelId + "]").removeClass("current_menu");
      } else {
          $(painelId).fadeToggle(800, function() {
              $(".panel").each(function() {
                  var painelOcultar = $(this).attr("id");
                  var painelOcultarId = "#" + painelOcultar;
                  if (painelOcultarId != painelId) {
                      $(this).fadeOut(800);
                  }
              });
          });
      }
  });
});