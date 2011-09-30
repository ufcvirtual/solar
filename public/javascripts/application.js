/*******************************************************************************
 * LightBox genérico do sistema
 * */
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
    lightBox = '<div id="lightBoxBackground" ' + modalClose + '>&nbsp;</div>';
    lightBox += dialog;
    $(document.body).append(lightBox);
    $("#lightBoxBackground").fadeTo("fast", 0.7, function() {
        $("#lightBoxDialog").slideDown("fast");
    });

    return false;

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

/*******************************************************************************
 * Atualiza o conteudo da tela por ajax.
 * Utilizado por funções genéricas de seleção como a paginação ou
 * a seleção de turmas.
 * */
function reloadContentByForm(form){
    var rscript = /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi;
    
    var type = $(form).attr("method");
    var url = '';//window.location;
    var selector = "#mysolar_content";
    var target = $("#mysolar_content");
    
    var params = '';
    var isFirst = true;
    $.each($(form).children(), function(index, value) {
        var name = $(value).attr("name");
        var val = $(value).attr("value");
        
        if (!isFirst)
            params += "&"
        params += name + "="+val;
        isFirst = false;
    });
    // Request the remote document
    jQuery.ajax({
        url: url,
        type: type,
        dataType: "html",
        data: params,//params,
        complete: function( jqXHR, status, responseText ) {
            responseText = jqXHR.responseText;
            target.html(jQuery("<div>").append(responseText.replace(rscript, "")).find(selector));

            // chamar a funcao que atualiza a agenda
            showAgenda();

            // atualiza clique em dia do mes


        }
    });
    return false;
}


/*******************************************************************************
 * Upload das imagens de usuário.
 * */
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

/*******************************************************************************
 * Código do Menu Accordion com estado salvo em cookies.
 * */
$(document).ready(function() {
    $('.mysolar_menu_title').click(function() {
        if ( $(this).parent().hasClass('mysolar_menu_title_active') == false ) {
            $('.mysolar_menu_title').each(function(){
                $(this).parent().removeClass('mysolar_menu_title_active').removeClass('mysolar_menu_title_single_active');
                $(this).next('.submenu').slideUp('fast');
            });
        }
        if ( $(this).parent().hasClass('mysolar_menu_title_single') == false ) {
            $(this).parent().addClass('mysolar_menu_title_active');
            $(this).next('.submenu').slideDown('fast');
        } else {
            $(this).parent().addClass('mysolar_menu_title_single_active');
        }
    });

    // abre menu corrente
    $('.open_menu').click();

    checkCookie();

    function setCookie(c_name,value,exdays)
    {
        var exdate=new Date();
        exdate.setDate(exdate.getDate() + exdays);
        var c_value=escape(value) + ((exdays==null) ? "" : "; expires="+exdate.toUTCString());
        document.cookie=c_name + "=" + c_value;
    }

    function getCookie(c_name)
    {
        var i,x,y;
        var ARRcookies=document.cookie.split(";");

        for (i=0;i<ARRcookies.length;i++)
        {
            x=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
            y=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);

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

        if (parent_id != null && parent_id!="")
        {
            $("#"+parent_id).children().show();
        }
    }
});


/*******************************************************************************
 * Extendendo o JQuery para Trabalhar bem com o REST. (Incluindo suporte aos métodos "PUT"  e "DELETE"
 * */
function _ajax_request(url, data, callback, type, method) {
    if (jQuery.isFunction(data)) {
        callback = data;
        data = {};
    }
    return jQuery.ajax({
        type: method,
        url: url,
        data: data,
        success: callback,
        dataType: type
    });
}

jQuery.extend({
    put: function(url, data, callback, type) {
        return _ajax_request(url, data, callback, type, 'PUT');
    },
    delete_: function(url, data, callback, type) {
        return _ajax_request(url, data, callback, type, 'DELETE');
    }
});
