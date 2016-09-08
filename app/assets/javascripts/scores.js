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

function open_tool(link){
  $.get($(link).data('url'), function(data){
    if(typeof data.method == 'undefined'){
      $(link).call_fancybox({
        href: data.url,
        open: true
      }); 
    }else{
      window.location.href = data.url;
    }
  }).error(function(data){
    var data = $.parseJSON(data.responseText);
    if (typeof(data.alert) != "undefined")
      flash_message(data.alert, 'alert');
  });
}

$(function(){
   $('.tb_list_students ul.dropdown-menu li input[type="checkbox"]').change(function(){
    if(!!$(this).prop('checked'))
      $('.'+$(this).val()).removeClass('invisible');
    else
      $('.'+$(this).val()).addClass('invisible');
   });

  $( ".tabs_index" ).tabs();
  $('.tabs_index li a').unbind('click');
  $('.tabs_index li a').click(function(){
    $.get($(this).data('url'), function(data){
      $('#list_of_students').replaceWith(data);
    }).error(function(data){
      var data = $.parseJSON(data.responseText);
      if (typeof(data.alert) != "undefined")
        flash_message(data.alert, 'alert');
    });
  });

  $(".expand, .compress").click(function(){
    $(this).parent().hide();
    $($(this).parent().siblings()[0]).show();
  });

  $('#scores #tabs li a').on('click', function(){
    $(this).parent().siblings().removeClass('active');
    $(this).parent().addClass('active');
  });

});