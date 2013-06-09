// = require jquery.mask.min

function show_special_needs(element){
  $(element).slideDown();
}

function hide_special_needs(element){
  $(element).slideUp();
}

jQuery(function ($) {
  /* mascaras para campos de CPF, telefone, celular (9 digitos no caso de São Paulo) e CEP */
  $("#cpf, #cpf-register").mask("999.999.999-99");
  $('#user_cell_phone, #cell_phone').mask('(00) 0000-0000',
    {onKeyPress: function(phone, e, currentField, options){
      var new_sp_phone = phone.match(/^(\(11\) 9(5[0-9]|6[0-9]|7[01234569]|8[0-9]|9[0-9])[0-9]{1})/g);
      new_sp_phone ? $(currentField).mask('(00) 00000-0000', options) : $(currentField).mask('(00) 0000-0000', options);
    }
  });
  $("#user_telephone").mask("(99)9999-9999");
  $("#user_zipcode").mask("99999-999");

    /* necessidades especiais no cadastro */
  $("#special_needs input:radio").click(function(){
    if ( $(this).val() == "true" ) {
      $("#special_needs_line").slideDown();
    } else {
      $("#special_needs_line").slideUp();
    }
  });

  /* permitir apenas números inteiros no campo de Número (Endereço de Cadastro) */
  $("#user_address_number").keydown(function(event) {
    // Allow: backspace, delete, tab, escape, and enter
    if ( event.keyCode == 46 || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 27 || event.keyCode == 13 ||
      // Allow: Ctrl+A
      (event.keyCode == 65 && event.ctrlKey === true) ||
      // Allow: Command/Meta
      (event.metaKey == true) ||
      // Allow: home, end, left, right
      (event.keyCode >= 35 && event.keyCode <= 39)) {
      // let it happen, don't do anything
      return;
    }
    else {
      // Ensure that it is a number and stop the keypress
      if (event.shiftKey || (event.keyCode < 48 || event.keyCode > 57) && (event.keyCode < 96 || event.keyCode > 105 )) {
        event.preventDefault();
      }
    }
  });
});