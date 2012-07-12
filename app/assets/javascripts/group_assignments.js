 function flash_message(msg, css_class) {
    if ($('#flash_message')) {  $('#flash_message').remove(); }
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

  function showImportGroupBox(url, title){
    showLightBoxURL(url, 500, 400, true, title);
    return false;
  } 

  function toggle_div(elementId) {
    $('#'+ elementId).slideToggle();
  }

// Botões

  function btn_manage_groups(assignment_id, show_import_button){
    group_name_label_to_text_field(assignment_id);
    $('#manage_group_assignment_'+assignment_id).hide();
    $('#save_changes_assignment_'+assignment_id).show();
    $('#cancel_changes_assignment_'+assignment_id).show();
    $(".group_participants").attr("class", "group_participants_manage");
    $(".group_assignment_name").attr("class", "group_assignment_name_manage");
    show_import_and_new_groups_box(show_import_button);
    dragndrop(assignment_id);
  }

  function student_mouseover(this_div, tooltip_message){
    student_div = $(this_div);
    student_can_move = student_div.attr('id');
    student_class = student_div.attr('class');

    if (student_can_move == 'true' && student_class.indexOf('ui-draggable') != -1 ){
      student_div.css("color","#134076");
      student_div.css("border-bottom","2px dashed #fdec9c");
      student_div.css("cursor", "crosshair");
      // url(smiley.gif),url(myBall.cur),auto
    } 
    if (student_can_move == 'false' && student_class.indexOf('ui-draggable') == -1 && $('.ui-draggable', student_div.parent().parent().parent()).length > 0){
      student_div.attr("title", tooltip_message);
      student_div.css("cursor", "default");
    }
  }

  function student_mouseout(this_div){
    student_div = $(this_div);
    student_can_move = student_div.attr('id');
    student_class = student_div.attr('class');
    
    if (student_can_move == 'true' && student_class.indexOf('ui-draggable') != -1){
      student_div.css("color","#000000");
      student_div.css("border-bottom","");
      student_div.css("cursor", "default");
    } 
  }

  function btn_new_group(assignment_id, message_empty_group) {
    var new_idx = "group_new_" + $('.another_new_group').length;

    var new_group_hmtl = new Array();
    new_group_hmtl.push('<div class="group_participants_manage another_new_group" id="' + new_idx + '">');
      new_group_hmtl.push('<div class="new_group" id="edit_'+new_idx+'">');
        new_group_hmtl.push('<input type="text_field" name="new_groups_names[][' + assignment_id + ']" id="text_field_'+ new_idx +'" class="rename_group" />');
        new_group_hmtl.push('<a onclick="delete_group(\'' + new_idx + '\', \'' + assignment_id + '\', false);">x</a>');
      new_group_hmtl.push('</div>');
      new_group_hmtl.push('<ul value="0">');
      new_group_hmtl.push('<li id="no_students_message">' + message_empty_group + '</li>')
      new_group_hmtl.push('</ul>');
    new_group_hmtl.push('</div>');
    // cria a nova div de novo grupo 
    $(new_group_hmtl.join('')).appendTo($('#group_assignment_content_'+assignment_id).last());
    // pega o último grupo criado
    var new_group_ul = $('.group_participants ul').last();
    // e permite que ele receba participantes
    active_droppable_element(new_group_ul, assignment_id);
  }

// Métodos

  function undo_btn_manage_groups_divs_changes(assignment_id, situation){
    $('#manage_group_assignment_'+assignment_id).show();
    $('#save_changes_assignment_'+assignment_id).hide();
    $('#cancel_changes_assignment_'+assignment_id).hide();
  }

  function group_name_label_to_text_field(assignment_id){
    // "recolhe" todos os text_fields dos grupos
    var all_text_fields_groups = document.getElementsByName("new_groups_names[]["+assignment_id+"]");
    for(var i = 0; i < all_text_fields_groups.length; i++) {
      // encontra a div com parte da edição de grupo e a div com a label
      var text_field = $('#edit_group_' + $(all_text_fields_groups[i]).attr('group_id'));
      var label = $('#group_name_'+ $(all_text_fields_groups[i]).attr('group_id'));
      label.hide();
      text_field.fadeIn();  
    }
  }

  function delete_group(group_div_id, assignment_id, has_files) {
    // apenas permite deleção se o grupo não tiver arquivos enviados
    if (!has_files){
      var deleted_div = $('#'+group_div_id);
      var all_li = $('li', deleted_div);
      for (var i = 0; i < all_li.length; i++){
        // remove os participantes do grupo e acrescenta na lista de sem grupo
        if($(all_li[i]).attr('id') != "no_students_message"){
          $(all_li[i]).appendTo($('#ul_no_group'));
        }
      }
      deleted_div.remove();
      // acrescenta o id da div do grupo apenas se não for um novo grupo sendo excluído
      if (group_div_id.indexOf('group_new') == -1) {
        deleted_groups.push(group_div_id);
      }
    }
  }

// Drag'n'drop

  function dragndrop(assignment_id){
    // habilita todos os <li> dessa atividade para serem "draggable"
    active_draggable_element($(".group_participants_manage li"));
    // desabilita os <li> que são apenas ilustrativos
    $("#no_students_message").draggable({ disabled: true });
    // habilita os grupos dessa atividade como elementos "droppable"
    active_droppable_element($(".group_participants_manage ul"));
  }

  function active_draggable_element(obj) {
    // cria objetos "draggable" a não ser que tenham id false
    // <li> de estudantes que já enviaram arquivos tem o id = false
    obj.not("#false").draggable({
      revert: true
    });
  }

  function active_droppable_element(obj) {
    // cria objetos "droppable"
    obj.droppable({
      accept: ".group_participants_manage li",
      hoverClass: "ui-state-active",
      drop: function( event, ui ) {
        // recolhe o id do estudante antes de remover o elemento que tem a informação
        var participant_id = ui.draggable.attr('value');
        // remove o elemento draggable da lista que esta sendo movido
        ui.draggable.remove();
        // cria novo elemento, mas agora no novo grupo a que ele foi levado
        $( "<li value='"+participant_id+"' id='true' style='position: relative;' class='ui-draggable' onmouseover='student_mouseover(this, \"no_message\");' onmouseout='student_mouseout(this);'></li>").text( ui.draggable.text() ).appendTo(this);
        // remove mensagem de "sem alunos" caso necessário
        if($('#no_students_message', this)){
          $('#no_students_message', this).remove();
        }
        // define como draggable o novo elemento criado
        active_draggable_element($(".group_participants_manage li"));
        // acrescenta mensagem de "sem alunos" caso necessário
        put_empty_message();
      }
    });
  }