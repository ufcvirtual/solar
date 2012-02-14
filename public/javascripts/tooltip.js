$(document).ready(function(){
  $('button').each(function(){
    var tooltip = $(this).attr('data-tooltip');
    if (tooltip != undefined && tooltip != '') {
      $(this).qtip({
        text: false,
        content: {
          text: function(api) {
            // Retrieve content from custom attribute of the $('.selector') elements.
            // var content = $(this).attr('data-tooltip');
            // return content === '' ? api.destroy() : content;
            return tooltip;
          }
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
          // classes: 'ui-tooltip-shadow ui-tooltip-dark'
          classes: 'ui-tooltip-tipsy'
        }
      });
    }
  })
})