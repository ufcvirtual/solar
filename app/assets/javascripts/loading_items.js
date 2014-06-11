// = require jquery.inview.min

$(function(){
  var loading_items = false;
  load_items();

  $(window).scroll(function(){
    load_items();
  });

  function load_items(){
    $('a[class^="load-more-"]').on('inview', function(e, visible) {
      if (loading_items || !visible)
        return;
      loading_items = true;
      return $.getScript($(this).attr('href'), function() {
        return loading_items = false;
      });
    });
  }

});