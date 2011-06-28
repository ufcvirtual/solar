// window file uploads
jQuery.fn.window_upload_files = function(options) {
    // default values
    var defaults = {
        dialog_id: 'dialog',
        mask_id: 'mask',
        class_window: 'window',
        class_close: 'close'
    };

    // verificando valores passados
    options = $.extend(defaults, options);

    var window_div = $(this);
    var window_upload = $('#' + options.dialog_id, window_div); // window
    var window_mask = $('#' + options.mask_id, window_div);

    // get the screen height and width
    //var maskHeight = $(document).height();
    //var maskWidth = $(window).width();

    // set height and width to mask to fill up the whole screen
    /*window_mask.css({
        'width': maskWidth,
        'height': maskHeight
    });*/

    // transition effect
    window_mask.fadeIn();
    window_mask.fadeTo("slow", 0.8);

    // get the window height and width
    //var winH = $(window).height();//50%
    //var winW = $(window).width();//50%

    // set the popup window to center
    window_upload.css('margin-top',  -(window_upload.height()/2));
    window_upload.css('margin-left', -(window_upload.width()/2));

    // transition effect
    window_upload.fadeIn(2000);

    // if close button is clicked
    $('.'+ options.class_window + ' .' + options.class_close).click(function (e) {
        e.preventDefault(); // cancel the link behavior
        $('#' + options.mask_id + ', .' + options.class_window).hide();
    });
}
