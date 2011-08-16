//Renderiza uma lightbox na página

function showLightBoxURL(url, width, height, canClose){
    //showLightBox('<p><center>...</center></p>', width, height, canClose);
    $('#forum_description').load(url,  function() {
        alert('Load was performed.');
    });

/*$.ajax({
          type: 'GET',
          url: url,
          cache: false,
          async: false,
          //context: document.body,
          success: function(response){
            alert('foi');
            showLightBox(response, width, height, canClose);
          }
          complete: function(response){
            // verifica se foi gerado algum erro
            if (parseInt(response.status) != 200) {
              alert('STATUS:' + response.status + ' Erro ao tentar consultar. Tente novamente em instantes.');
            }
          }
        });*/
}

function showLightBox(content, width, height, canClose){
    if (width == null)
        width = 500;
    if (height == null)
        height = 500;
    if (canClose == null)
        canClose = true;

    var halfWidth = Math.floor(width/2);
    var halfHeight = Math.floor(height/2);
    var modalClose = '';
    var lightBox = '';
    var dialog = '';
    
    if (canClose)
        modalClose = 'onclick="removeLightBox();" ';

    removeLightBox();
    dialog = '<div id="lightBoxDialog" style="border:1px solid #000;display:none;width:'+width+'px;height:'+height+'px;background-color:#AAA;position:absolute;z-index:1001;top:50%; left:50%; margin-top:-'+halfHeight+'px;margin-left:-'+halfWidth+'px;">'+ content + '</div>'
    lightBox = '<div id="lightBoxBackground" ' + modalClose + ' style="display:none;width:100%;height:100%;position:fixed;top:0px;left:0px;background-color:#000;z-index:1000;">&nbsp;</div>';
    lightBox += dialog;
    $(document.body).append(lightBox);
    $("#lightBoxBackground").fadeTo("400", 0.7, function() {
        $("#lightBoxDialog").slideDown("400");
    });

}

function removeLightBox(){
    $("#lightBoxDialog").slideUp("400", function() {
        $("#lightBoxBackground").fadeOut("400", function() {
            $('#lightBoxBackground').remove();
            $('#lightBoxDialog').remove();
        });
    });
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
