// = require jquery.mask.min

function show_special_needs(element){
  $(element).slideDown();
}

function hide_special_needs(element){
  $(element).slideUp();
}

jQuery(function($){
  $("#cpf").mask("999.999.999-99");
  $("#cpf-regiter").mask("999.999.999-99");
  $("#user_cpf").mask("999.999.999-99");
  $("#user_telephone").mask("(99)9999-9999");
  $("#user_cell_phone").mask("(99)9999-9999");
  $("#cell_phone").mask("(99)9999-9999");
  $("#user_zipcode").mask("99999-999");
});
