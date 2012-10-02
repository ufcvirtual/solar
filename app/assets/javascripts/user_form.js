function show_special_needs(element){
  $(element).slideDown();
}
function hide_special_needs(element){
  $(element).slideUp();
}

jQuery(function($){
    $("#cpf").mask("999.999.999-99");
    $("#telephone").mask("(99)9999-9999");
    $("#cell_phone").mask("(99)9999-9999");
    $("#zipcode").mask("99999-999");
});