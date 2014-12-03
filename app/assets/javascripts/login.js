// = require menus
// = require panels

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

function open_registration_tab() {
    //event.preventDefault();
    $("#register-bt").removeClass("inactive");
    $("#login-bt").addClass("inactive");
    $("#login-form").hide();
    $("#login-register").show();
    placeholder();
}

function open_login_tab() {
    //event.preventDefault();
    $("#login-form").show();
    $("#login-register").hide();
    $("#login-bt").removeClass("inactive");
    $("#register-bt").addClass("inactive");
}

/* verificando se a URL está direcionando para o painel de registro */
$(function(){
    var hashVal = window.location.hash.split("#")[1];
    if (hashVal == "login-register") {
        open_registration_tab();
        $("#cpf-register").focus();
    }
});

/****************************************************
 * scripts das áreas de cadastro e login
 ****************************************************/
$(function() {
    placeholder();
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