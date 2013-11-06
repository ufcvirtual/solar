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

function select_none() {
  $('[type=checkbox]').map(function(){ $(this).attr("checked",false) });
}

function selected_messages() {
  return $('[type=checkbox]:checked.selected_messages').map(function(){ return $(this).data('message-id') }).get();
}

function message_menu_dropdown() {
  $(".message_status").change(function() {
    select_none();
    if ( $( "select option:selected" ).hasClass("check_all") )
      show_all();
    if ( $( "select option:selected" ).hasClass("check_read") )
    {
      hide_unreads();
      show_reads();
    }
    if ( $( "select option:selected" ).hasClass("check_unread") )
    {
      show_unreads();
      hide_reads();
    }
  });
}

function message_add_receiver(u,name,email){
  var new_to = name + " [" + email + "], ";
  var new_recipient = "<span onclick="+"$('#"+u+"').show();$(this).remove()" + " class='message_recipient_box' >"+new_to+"</span>";

  var atual_recipients = $("#recipients_selected").text();
  var found = atual_recipients.search(email);
  $("#receiver_already_added").remove();
  if (found == -1) {
    $("#recipients_selected").append(new_recipient);
    $("#"+u).hide();
  }else{
    $("<span id='receiver_already_added'>#{t(:message_receiver_already_added)}</span>").hide().appendTo($("#"+u).children()[0]).fadeIn();
  }
}

/**
 * Manipulação de arquivos anexos
 */
function message_add_new_file() {
  var new_form = $("[name='files[]']:first").clone();
  $(new_form).insertAfter( $("[name='files[]']:last") );
  $(new_form).click();

  $(new_form).change(function(){
    var new_file_name = "<div class='input files file_attached'>" + this.files[0].name + "<i class='icon-cross remove_file'></i> </span> </div>";

    if ($(".list_files_to_send .files:last").lenght)
      $(".list_files_to_send .files:last").after(new_file_name);
    else
      $(".list_files_to_send").append(new_file_name);

    $(".remove_file:last").click(function(){
      $(new_form).remove();
      $(this).parents('div.input.files').remove();
    });
  });
}

function validate_sending() {
  var receiver = $('#to').val().trim();
  if (receiver=='')
    return false;
};
