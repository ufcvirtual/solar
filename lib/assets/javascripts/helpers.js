/*********************************************
 * Funcoes genericas
 *********************************************/

/**
 * Upload das imagens de usuário.
 */
function showUserPictureUploadForm(url, title){
  showLightBoxURL(url, 500, 400, true, title);
  return false;
}

function mysolarTopSubmenuToggle(){
  var left = $("#mysolar_top_user_nick").offset().left;
  var origin = $("#mysolar_topbar").offset().left;
  left -= origin;
  $("#mysolar_top_submenu").css('left', left);
  $("#mysolar_top_submenu").slideToggle(150);
  $('#mysolar_top_submenu_label').toggleClass('mysolar_top_submenu_label_selected');
  $('#mysolar_top_submenu_label').toggleClass('mysolar_top_submenu_label_regular');
}

function mysolarTopSubmenuHelpToggle(){
  var left = $("#help_top").offset().left;
  var origin = $("#mysolar_topbar").offset().left;
  left -= origin;
  $("#mysolar_submenu_help").css('left', left);
  $("#mysolar_submenu_help").slideToggle(150);
  $('#mysolar_top_help').toggleClass('mysolar_top_submenu_label_selected');
  $('#mysolar_top_help').toggleClass('mysolar_top_submenu_label_regular');
}

/**
 * Flash messages
 */

function flash_message(msg, css_class, div_to_show, onclick_function) {
  var div_to_show = (typeof div_to_show == "undefined") ? $(".flash_message_wrapper:last") : $("." + div_to_show);

  if(typeof div_to_show == "undefined"){
    div_to_show = $(".flash_message_wrapper");
    if(!div_to_show.parents('.undefined-sticky-wrapper').length())
      div_to_show.height($("#flash_message").height() + 20);
  }

  erase_flash_messages();
  if (typeof onclick_function != "undefined")
    var onclick_function = onclick_function + "()";
  var html = '<div id="flash_message" class="' + css_class + '" onclick='+onclick_function+'><span>' + msg + '</span><span class="close"><a onclick="javascript:erase_flash_messages()" href="#"><i class="icon-cross"></i></a></span></div>';
  div_to_show.prepend($(html));
  $("#flash_message").closest(".sticky-wrapper").css("height","40px").css("width", "auto");
  $("#flash_message").effect("highlight","slow");
}

function erase_flash_messages() {
  if ($('#flash_message')) {
    $('#flash_message').closest(".sticky-wrapper").css("height","0");
    $(".flash_message_wrapper").children().remove()
    $("#flash_message").remove();
  }
}

/******************************************************************************************************
 * Extendendo o JQuery para Trabalhar bem com o REST. (Incluindo suporte aos métodos "PUT"  e "DELETE")
 ******************************************************************************************************/
function _ajax_request(url, data, callback, type, method) {
  if (jQuery.isFunction(data)) {
    callback = data;
    data = {};
  }

  if (typeof(type) == "undefined")
    type = "json";

  return jQuery.ajax({
    type: method,
    url: url,
    data: data,
    success: callback,
    dataType: type
  });
}

function update_tables_with_no_data() {
  $('.tb_list').each(function(){
    var rowCount = $('tbody>tr:visible', $(this)).length;
    if (rowCount == 0){
      $('.empty_message', $(this).closest('.block_content')).removeClass('hide_message');
      $('thead', $(this)).hide();
    } else {
      $('thead', $(this)).show();
      $('.empty_message', $(this).closest('.block_content')).addClass('hide_message');
    }
  });
}

function show_error(data, message, div){
  if (message == undefined || message == null)
    var message = $.parseJSON(data.responseText).alert;
  if (message != "undefined")
    flash_message(message, "alert", div);
}

jQuery.extend({
  put: function(url, data, callback, type) {
    return _ajax_request(url, data, callback, type, 'PUT');
  },
  delete: function(url, data, callback, type) {
    return _ajax_request(url, data, callback, type, 'DELETE');
  }
});

$.fn.is_empty = function(){
  return ($(this).val() == "" || $(this).val() == null || $(this) == []);
}

// se for necessário abrir o fancybox no momento da chamada do método, se faz necessário passar um parâmetro "open"
$.fn.call_fancybox = function (options) {
  erase_flash_messages();

  if (typeof(options) == "undefined")
    options = {};

  $(this).addClass("fancybox.ajax");

  /**
  * live: false
  *   é necessário para que, ao abrir um fancybox x vezes em uma determinada página, não sejam realizados x+1 requests a cada nova chamada
  * modal: true
  *   como janela modal, o usuário só vai poder fechar o fancybox ao clicar no botão de "cancelar"
  **/

  $.extend( options, { live: false, modal: false, helpers: { overlay: { locked: true, closeClick: false }, autoDimensions: true, width: '100px' } } );

  if (typeof(options.open) != "undefined") // abrir na chamada
    $.fancybox.open($(this), options);
  else
    $(this).fancybox(options);

  return false;
}

// Catch the click of a link to undo action in a flash_message
$.fn.undo_action_by_flash_message = function(options){
  if (typeof options == "undefined")
    options = {};

  if (typeof(options) != "undefined" && typeof(options.success) == "undefined") { // definir success
    options.success = function(data) {
      if (typeof(data.msg) != "undefined")
        flash_message(data.msg, 'notice');

      if (typeof(options.complement_success) == "function")
        options.complement_success(data); // desired response for success
    }
  }

  if (typeof(options.error) == "undefined") {
    options.error = function(data) {
      var data = $.parseJSON(data.responseText);
      if (typeof(data.msg) != "undefined")
        flash_message(data.msg, 'alert');
    }
  }

  $("#flash_message a#undo_action").click(function(){
    $.ajax({
      dataType: "json",
      method: "PUT",
      url: $(this).data("link"), // link to action which will undo user's previous actions
      success: options.success,
      error: options.error
    });
  });
}


/* Dealing with colors */

/* obtained at http://stackoverflow.com/questions/43044/algorithm-to-randomly-generate-an-aesthetically-pleasing-color-palette*/
function pastelColors(){
  var r = (Math.round(Math.random()* 127) + 127).toString(16);
  var g = (Math.round(Math.random()* 127) + 127).toString(16);
  var b = (Math.round(Math.random()* 127) + 127).toString(16);
  return '#' + r + g + b;
}

/* Expand and compress text */
function expand_or_compress(icon){
  $(icon).parent().hide();
  $($(icon).parent().siblings()[0]).show();
}

/* Save values from ckeditor to related textarea */
function save_values_ckeditor(){
  for(name in CKEDITOR.instances){
    var content = $('#'+CKEDITOR.instances[name].id+'_contents iframe').contents().find('body').html();
    if (content != "<p><br></p>" && content != "")
      $('#'+name).val(content);
  }
}