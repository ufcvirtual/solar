// = require jquery.mask.min

function show_special_needs(element){
  $(element).slideDown();
}

function hide_special_needs(element){
  $(element).slideUp();
}

jQuery(function ($) {
  $("#cpf, #cpf-register").mask("999.999.999-99");
//  $("#user_telephone").mask("(99)9999-99999");
  $('#user_cell_phone, #cell_phone').mask('(00) 0000-0000',
    {onKeyPress: function(phone, e, currentField, options){
      var new_sp_phone = phone.match(/^(\(11\) 9(5[0-9]|6[0-9]|7[01234569]|8[0-9]|9[0-9])[0-9]{1})/g);
      new_sp_phone ? $(currentField).mask('(00) 00000-0000', options) : $(currentField).mask('(00) 0000-0000', options);
    }
  });
  $("#user_telephone").mask("(99)9999-9999");
  $("#user_zipcode").mask("99999-999");
});