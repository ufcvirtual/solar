$(document).ready(function(){
  $('*[data-tooltip]').qtip({
    content: {
      attr: 'data-tooltip'
    },
    position: {
      my: 'top center',
      at: 'bottom center',
      viewport: $(window),
      adjust: {
        y: 2
      }
    },
    style: {
      classes: 'qtip-tipsy'
    }
  });
});