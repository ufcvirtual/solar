function show_reads() {
  $('.message_read').parents('tr').fadeIn(1).removeClass('fade');
}

function hide_reads() {
  $('.message_read').parents('tr').fadeOut(1).addClass('fade');
}

function show_unreads() {
  $('.message_unread').parents('tr').fadeIn(1).removeClass('fade');
}

function hide_unreads() {
  $('.message_unread').parents('tr').fadeOut(1).addClass('fade');
}

function show_all() {
  $('[type=checkbox]').removeAttr('checked');
  show_reads();
  show_unreads();
}

function selected_messages() {
  return $('[type=checkbox]:checked.selected_messages').map(function(){ return $(this).data('message-id') }).get();
}

function message_menu_dropdown() {
  $('#check_all').click(function(){
    show_all();
  });

  $('#check_read').click(function(){
    hide_unreads();
    show_reads();
  });

  $('#check_unread').click(function(){
    show_unreads();
    hide_reads();
  });
}
