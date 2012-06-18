 function flash_message(msg, css_class) {
    if ($('#flash_message')) { $('#flash_message').remove(); }
    var html = '<div id="flash_message" class="' + css_class + '"><span>' + msg + '</span></div>';
    $('.flash_message_wrapper').append(html);
  }

  function clickOnGroup(group_div_id){
    this_div = $('#students_'+group_div_id);
    if (this_div.css('display') == 'none'){
      this_div.slideDown(); 
      this_div.parents('li').find('.menu_icon_arrow').addClass('menu_icon_animate');
    }else{
      this_div.slideUp(); 
      this_div.parents('li').find('.menu_icon_animate').removeClass('menu_icon_animate');
    }
  }

  function changeOpendedGroupArrow(group_assignment_id){
    this_div = $('#students_'+group_assignment_id);
    if (this_div.css('display') == 'block'){
      this_div.parents('li').find('.menu_icon_arrow').addClass('menu_icon_animate');
    }
  }

function showImportGroupBox(url, title){
    showLightBoxURL(url, 500, 400, true, title);
    return false;
}