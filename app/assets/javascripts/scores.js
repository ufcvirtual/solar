function open_evaluation(link){
  $.get($(link).data('url'), function(data){
    if(typeof data.method == 'undefined'){
      $(link).call_fancybox({
        href: data.url,
        open: true
      }); 
    }else{
      if(data.method != 'get'){
        $.ajax({
          type: data.method,
          url: data.url,
          success: function(data){ 
            flash_message(data.notice, 'notice');
          }
        })
      }else{
        window.location.href = data.url;
      }
    }
  }).error(function(data){
    var data = $.parseJSON(data.responseText);
    if (typeof(data.alert) != "undefined")
      flash_message(data.alert, 'alert');
  });
}

$(function(){
   $('ul.dropdown-menu li input[type="checkbox"]').change(function(){
    if(!!$(this).prop('checked'))
      $('.'+$(this).val()).removeClass('invisible');
    else
      $('.'+$(this).val()).addClass('invisible');
   });

  $( "#tabs" ).tabs();
  $('#tabs li a').unbind('click');
  $('#tabs li a').click(function(){
    $.get($(this).data('url'), function(data){
      $('#list_of_students').replaceWith(data);
    });
  });
});