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

function showImportGroupBox(url, title){
  showLightBoxURL(url, 500, 400, true, title);
  return false;
} 

// Botões

function btn_manage_groups(assignment_id, show_import_button){
  group_name_label_to_text_field();
  toggle_divs();
  $(".evaluate_group").hide();
  $(".group_participants").attr("class", "group_participants_manage");
  $(".group_name_true").attr("class", "group_name_manage");
  $(".group_name_false").attr("class", "disabled_groups_assignments_name");
  $(".group_information_true").attr("class", "group_information_manage");
  $(".group_information_false").attr("class", "disabled_groups_assignments_information");
  dragndrop(assignment_id);
  show_import_and_new_groups_box(show_import_button);
}

function btn_new_group(assignment_id, message_empty_group, new_group_message) {
  var new_idx = "group_new_" + $('.another_new_group').length;
  var new_group_hmtl = new Array();

  new_group_hmtl.push('<div class="group_participants_manage another_new_group " id="' + new_idx + '">');
    new_group_hmtl.push('<div class="new_group edit_group_true" id="edit_'+new_idx+'">');
      new_group_hmtl.push('<input type="text_field" value="'+new_group_message+'" name="new_groups_names[][' + assignment_id + ']" id="text_field_'+ new_idx +'" class="rename_group" />');
      new_group_hmtl.push('<a class="remove_group" onclick="delete_group(\'' + new_idx + '\', \'' + assignment_id + '\', false);"> x</a>');
    new_group_hmtl.push('</div>');
    new_group_hmtl.push('<ul value="0">');
    new_group_hmtl.push('<li class="no_students_message">' + message_empty_group + '</li>')
    new_group_hmtl.push('</ul>');
  new_group_hmtl.push('</div>');
  
  $(new_group_hmtl.join('')).appendTo($('.group_assignment_content').last()); // cria a nova div de novo grupo 
  var new_group_ul = $('.group_participants_manage ul').last(); // pega o último grupo criado
  
  active_droppable_element(new_group_ul, ".group_participants_manage li", "#false"); // e permite que ele receba participantes
}

// Métodos

function toggle_divs(){
  $('#manage_group_assignment').toggle();
  $('#save_changes_assignment').toggle();
  $('#cancel_changes_assignment').toggle();
}

function undo_btn_manage_groups_divs_changes(){
  toggle_divs();
  $('.group_assignments_manage_buttons').remove();
}

function student_mouseover(this_div, tooltip_message){
  student_div = $(this_div);
  student_can_move = student_div.attr('id');
  student_class = student_div.attr('class');
  student_group_can_change = student_div.parent().attr('id');

  if ((student_can_move != 'false' && student_group_can_change != "false") && student_class.indexOf('ui-draggable') != -1 ){
    student_div.addClass('draggable_student');
  } 

  if ((student_can_move == 'false' || student_group_can_change == "false") && $('.ui-draggable', student_div.parent().parent().parent()).length > 0){
    student_div.attr("title", tooltip_message);
    student_div.removeClass('draggable_student');
  }
}

function student_mouseout(this_div){
  student_div = $(this_div);
  student_can_move = student_div.attr('id');
  student_class = student_div.attr('class');
  student_group_can_change = student_div.parent().attr('class');
  
  if ((student_can_move != 'false' && student_group_can_change != "false") && student_class.indexOf('ui-draggable') != -1){
    student_div.removeClass('draggable_student');
  } 
}

function group_name_label_to_text_field(){
  var text_field = $('.edit_group_true').fadeIn();
  var label = $('.group_name_true').hide();
}

function delete_group(group_div_id, assignment_id, can_manage_group) {
  // apenas permite deleção se o grupo não tiver arquivos enviados
  if (can_manage_group){
    var deleted_div = $('#'+group_div_id);
    var all_li = $('li', deleted_div); // todos os "li" de uma "ul" = todos os participantes de um grupo

    all_li.each(function(i){
      if($(all_li[i]).attr('class').indexOf("no_students_message") == -1){
        $(all_li[i]).appendTo($('.ul_no_group'));  // remove os participantes do grupo e acrescenta na lista de sem grupo
        $('.ul_no_group > .no_students_message').remove(); // remove a mensagem de "sem participantes" em "alunos sem grupo"
      }
    });

    deleted_div.remove(); // remove o grupo

    if (group_div_id.indexOf('group_new') == -1) { //se não for um novo grupo sendo excluído
      deleted_groups.push(group_div_id); // acrescenta o id da div do grupo aos grupos excluídos
    }

  }
}

// Drag'n'drop

function dragndrop(assignment_id){
  active_draggable_element($(".group_participants_manage li"), "#false"); // habilita todos os <li> dessa atividade para serem "draggable", exceto os com id "false"
  $(".no_students_message").draggable({ disabled: true }); // desabilita os <li> que são apenas ilustrativos (no caso: "grupo sem participantes")
  groups_cant_manage = $("#false"); 
  groups_cant_manage.each(function(i){
    $('li', groups_cant_manage.eq(i)).draggable({ disabled: true }); // desabilita os <li> de grupos que não podem ser alterados
  });
  // habilita os grupos dessa atividade como elementos "droppable", exceto os com id "false"
  active_droppable_element($(".group_participants_manage ul"), ".group_participants_manage li", "#false"); 
}

function active_draggable_element(draggable_div, except) {
  // cria divs "draggable" a não ser que tenham id false
  // <li> de estudantes que já enviaram arquivos ou que já foram avaliados tem o id = false
  draggable_div.not(except).draggable({
    revert: true
  });
}

function active_droppable_element(droppable_div, div_acepted, except) {
  // cria divs "droppable" a não ser que tenham id false
  // <ul> de grupos que já foram avaliados tem o id = false
  droppable_div.not(except).droppable({
    accept: div_acepted,
    drop: function( event, ui ) {
      var participant_id = ui.draggable.attr('value'); // recolhe o id do estudante antes de remover o elemento que tem a informação
      ui.draggable.remove(); // remove o elemento draggable da lista que esta sendo movido
      // cria novo elemento, mas agora no novo grupo a que ele foi levado
      $( "<li value='"+participant_id+"' id='true' style='position: relative;' class='ui-draggable' onmouseover='student_mouseover(this, \"no_message\");' onmouseout='student_mouseout(this);'></li>").text( ui.draggable.text() ).appendTo(this);
      
      if($('.no_students_message', this)){ // caso exista a mensagem de "sem alunos" no grupo que está recebendo o aluno
        $('.no_students_message', this).remove(); // remove mensagem
      }
      active_draggable_element($(".group_participants_manage li"), "#false"); // redefine como draggable os <li>
      put_empty_message(); // acrescenta mensagem de "sem alunos", caso necessário, ao grupo que teve o aluno removido
    }
  });
}
