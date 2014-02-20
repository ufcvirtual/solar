$(function() {
  /* Menus de idiomas e tutorial */
  var menu_tutorial = $(".choice-tutorial-menu");
  var menu_language = $(".choice-language-menu");
  /* ocultar menus ao clicar no documento */
  $(document).on("click", function() {
      $(menu_tutorial).hide();
      $(menu_language).hide();
  });
  function menu(item, itemMenu) {
      //event.preventDefault();
      //event.stopPropagation();
      $(itemMenu, item).toggle().position({
          my: "center-7 bottom",
          at: "center top-5",
          of: item
      });
  }
  $(".choice-tutorial > a, .choice-language > a").on("click", function(event) {
      event.preventDefault();
      event.stopPropagation();
      $(menu_tutorial).hide();
      $(menu_language).hide();
      var item = $(this).parent();
      var itemMenu = "." + $(item).attr("class") + "-menu";
      menu(item, itemMenu);
  });
});