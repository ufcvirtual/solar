/**
  Funções relativas à renderização de uma lightBox
**/

function showLightBoxURL(url, width, height, canClose, title){
    showLightBox('', width, height, canClose,title);

    $("#lightBoxDialogContent").load(url , function(response, status, xhr) {
        if (status == "error") {
            var msg = "Erro na aplicação.\n Por favor, aguarde alguns instantes.";//internacionalizar
            alert(msg);
        }
    });
}

function showLightBox(content, width, height, canClose, title){
    if (width == null)
        width = 500;
    if (height == null)
        height = 300;
    if (canClose == null)
        canClose = true;

    var halfWidth = Math.floor(width/2);
    var halfHeight = Math.floor(height/2);
    var modalClose = '';
    var lightBox = '';
    var dialog = '';
    var closeBt = '';

    if (canClose){
        modalClose = 'onclick="removeLightBox();" ';
        closeBt = '<div ' + modalClose + ' id="lightBoxDialogCloseBt">&nbsp;</div>';
    }
    title = '<div id="lightBoxDialogTitle">'+title+'</div>'
    
    removeLightBox(true);
    dialog = '<div id="lightBoxDialog" style="width:'+width+'px;height:'+height+'px;margin-top:-'+halfHeight+'px;margin-left:-'+halfWidth+'px;">'
        + closeBt
        + title
        + '<div id="lightBoxDialogContent">'
        + content
        + '</div>'
    lightBox = '<div id="lightBoxBackground" ' + modalClose + '">&nbsp;</div>';
    lightBox += dialog;
    $(document.body).append(lightBox);
    $("#lightBoxBackground").fadeTo("fast", 0.7, function() {
        $("#lightBoxDialog").slideDown("fast");
    });

}

function removeLightBox(force){
    if (force == null){
        $("#lightBoxDialog").slideUp("400", function() {
            $("#lightBoxBackground").fadeOut("400", function() {
                $('#lightBoxBackground').remove();
                $('#lightBoxDialog').remove();
            });
        });
        return;
    }
    $('#lightBoxBackground').remove();
    $('#lightBoxDialog').remove();
}

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

    // transition effect
    window_mask.fadeIn();
    window_mask.fadeTo("slow", 0.8);

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
//Parte do menu//
//Esse código faz o acordion do menu e serve para guardar o estado do dele por meio de cookies//

$(document).ready(function() {
    $('.mysolar_menu_title').click(function() {
        if($(this).siblings().is(':visible')){
            $('.mysolar_menu_list').slideUp("fast");
        } else {
            $('.mysolar_menu_list').slideUp("fast");
            $(this).siblings().slideDown("fast");
        }
        checkCookie();
    });

    //        alert('abaixo: ' + $.cookie("father_id"));

    checkCookie();

    function setCookie(c_name,value,exdays)
    {
        //alert('setou: '+value);
        var exdate=new Date();
        exdate.setDate(exdate.getDate() + exdays);
        var c_value=escape(value) + ((exdays==null) ? "" : "; expires="+exdate.toUTCString());
        document.cookie=c_name + "=" + c_value;
    }

    function getCookie(c_name)
    {
        var i,x,y;
        var ARRcookies=document.cookie.split(";");

        //alert('getCookie[' + document.cookie + ']');

        for (i=0;i<ARRcookies.length;i++)
        {
            x=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
            y=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
            //alert('get'+i+': ' + y);
            x=x.replace(/^\s+|\s+$/g,"");
            if (x==c_name)
            {
                return unescape(y);
            }
        }
    }

    function checkCookie()
    {
        var parent_id = getCookie("parent_id");

        //alert('checou: '+parent_id);

        if (parent_id != null && parent_id!="")
        {
            //alert('VERIFICOU: '+parent_id);
            $("#"+parent_id).siblings().show();
        }
    }

//Rever esse código aqui!
/*$('.mysolar_top_link').click(function(){
            setCookie("parent_id",null,-1);
          });*/

});
