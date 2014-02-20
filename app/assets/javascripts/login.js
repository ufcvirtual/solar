// = require menus

/* Implementando método alternativo ao placeholder no IE < 9 */
function placeholder() {
    $.support.placeholder = "placeholder" in document.createElement("input");
    if (!$.support.placeholder) {
        /* criação de um campo falso de senha, do tipo texto, para exibir o valor 'Senha' */
        var fakePassword = "<input type='text' name='fake_pass' id='fake_pass' value='Senha' style='display:none'/>";
        /* adicionar o input fake, ocultar o real e exibir o fake */
        var loginDiv = $("#login-form");
        $("#password", loginDiv).before(fakePassword).hide();
        $("#fake_pass", loginDiv).show();
        $("#fake_pass", loginDiv).focus(function() {
            $(this).hide();
            $("#password", loginDiv).show().focus();
        });
        $("#password", loginDiv).blur(function() {
            if ($(this).val() === "") {
                $(this).hide();
                $("#fake_pass").show();
            }
        });
        /* nos outros campos, pegar o valor do atributo placeholder e colocar como value */
        $("input[placeholder]").each(function() {
            var ph = $(this).attr("placeholder");
            $(this).val(ph).focus(function() {
                if ($(this).val() == ph) $(this).val("");
            }).blur(function() {
                if (!$(this).val()) $(this).val(ph);
            });
        });
    }
}

function open_registration_tab(object) {
    //event.preventDefault();
    $(object).parent().removeClass("inactive");
    $("#login-bt").addClass("inactive");
    $("#login-form").hide();
    $("#login-register").show();
    placeholder();
}

function open_login_tab(object) {
    //event.preventDefault();
    $("#login-form").show();
    $("#login-register").hide();
    $(object).parent().removeClass("inactive");
    $("#register-bt").addClass("inactive");
}

/****************************************************
 * scripts das áreas de cadastro e login
 ****************************************************/
$(function() {
    placeholder();
    /* script dos paineis de informacao */
    $(".panel .arrow").click(function() {
        $(".menu_footer a").removeClass("current_menu");
        $(".panel").fadeOut();
    });
    $(".menu_footer a.panel-link").click(function(event) {
        event.preventDefault();
        var painelId = $(this).attr("href");
        $(".menu_footer a.panel-link").removeClass("current_menu");
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
    /* Passo-a-passo da página de cadastro*/
    $(".next").click(function(event) {
        event.preventDefault();
        var btnParent = $(this).parents(".form-panel");
        var btnParentId = $(btnParent).attr("id");
        var btnParentNext = $(btnParent).next("div");
        var btnParentNextId = $(btnParentNext).attr("id");
        $("#register-steps .dot").removeClass("active");
        $("#dot-" + btnParentId).addClass("done");
        $("#dot-" + btnParentNextId).addClass("active");
        $("#register-steps li").removeClass("active");
        $("#dot-" + btnParentNextId).parent("li").addClass("active");
        $(btnParent).hide();
        $(btnParentNext).show();
    });
    $(".back").click(function(event) {
        event.preventDefault();
        var btnParent = $(this).parents(".form-panel");
        var btnParentPrevious = $(btnParent).prev("div");
        var btnParentPreviousId = $(btnParentPrevious).attr("id");
        $("#register-steps .dot").removeClass("active");
        $("#dot-" + btnParentPreviousId).removeClass("done").addClass("active");
        $("#register-steps li").removeClass("active");
        $("#dot-" + btnParentPreviousId).parent("li").addClass("active");
        $(btnParent).hide();
        $(btnParentPrevious).show();
    });
});