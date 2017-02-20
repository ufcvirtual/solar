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
    if(typeof(data.method) == 'undefined'){
      $(link).call_fancybox({
        href: data.url,
        open: true
      }); 
    }else{
      if(data.web != undefined){
        $.get(data.url, function(data2){
          window.open(data2.url, '_blank');
        });
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

function change_tab(tab){
  $.get($(tab).data('url'), function(data){
    $('.tb_list_students').html(data);
    $('#tabs a.active').removeClass('active');
    $('.tabs a.active').removeClass('active');
    $(tab).addClass('active');
  }).error(function(data){
    var data = $.parseJSON(data.responseText);
    if (typeof(data.alert) != "undefined")
      flash_message(data.alert, 'alert');
  });
}

function change_tab_tool(tab){
  var parent = $(tab).parents('section');
  $('.tools', parent).removeClass('show');
  $($(tab).data('div'), parent).addClass('show');
  $('#tabs a.active', parent).removeClass('active');
  $('.tabs a.active', parent).removeClass('active');
  $(tab).addClass('active');
  return false;
}

$(function(){
   $('.tb_list_students ul.dropdown-menu li input[type="checkbox"]').change(function(){
    if(!!$(this).prop('checked'))
      $('.'+$(this).val()).removeClass('invisible');
    else
      $('.'+$(this).val()).addClass('invisible');
   });

  $(".expand, .compress").click(function(){
    $(this).parent().hide();
    $($(this).parent().siblings()[0]).show();
  });

});