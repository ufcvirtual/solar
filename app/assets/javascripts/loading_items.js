// = require jquery.inview.min

$(function(){
  var loading_allocations = false;
  load_allocations();

  $(window).scroll(function(){
    load_allocations();
  });

  function load_allocations(){
    $('a.load-more-allocations').on('inview', function(e, visible) {
      if (loading_allocations || !visible)
        return;
      loading_allocations = true;
      return $.getScript($(this).attr('href'), function() {
        return loading_allocations = false;
      });
    });
  }

});