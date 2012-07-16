$(function() {
  $('.enrollments input:checkbox').click(function() {
    if ( $(this).attr("id") == 'cbx_all' ) {
      var cbx_all = this;
      $('.cbx_value').each(function() { $(this).attr('checked', $(cbx_all).attr('checked')); });
    } else if ( $(this).attr('checked') == false && $('#cbx_all').attr('checked') == true ) {
      $('#cbx_all').attr('checked', false);
    } else if ( $(this).attr('checked') == true && $('.cbx_value').length == $('.cbx_value:checked').length ) {
      $('#cbx_all').attr('checked', true);
    }

    // habilitar botao de gerencia de registros selecionados
    if ($('.cbx_value:checked').length > 0) {
      $('.btn_manage_enrollment_selected').removeClass('btn_disable');
    } else {
      $('.btn_manage_enrollment_selected').addClass('btn_disable');
    }
  });

  $('.btn_manage_enrollment_selected').click(function() {
    var ch = $('.cbx_value:checked');

    if (ch.length == 0) { // nenhum selecionado
      alert('<%= t(:error_no_item_selected) %>');
      return;
    } else { // verificar se todos os selecionados possuem o mesmo status
      for (var i = 1; i < ch.length; i++) {
        if ( $(ch[i]).attr('status-value') != $(ch[i-1]).attr('status-value')) {
          alert('<%= t(:allocation_manage_error_not_same_status) %>');
          return;
        }
      }
    }

    var sel = new Array();
    if (ch.length > 0) {
      for (var i = 0; i < ch.length; i++) {
        sel.push(ch[i].value);
      }
    }
    var url = "<%= edit_allocation_path('something', :multiple => 'yes') %>".replace('something', sel.join(','));
    showLightBoxURL(url, 400, 250, true, '<%= t(:allocation_manage_selected)%>');
  });
});

function manage_cancel(obj) {
  $.get($(obj).attr('show-link'), function(data) { $(obj).closest('tr').html(data); });
}

function manage_enrollment(obj) {
  $.get($(obj).attr('edit-link'), function(data) { $(obj).closest('tr').html(data); });
}

function save_allocation(obj) {
  $.ajax({
    type: 'PUT',
    url: $(obj).attr('save-link'),
    data: {
      "id": $(obj).attr('allocation-id'),
      "allocation": {
        "status": $('#status_id option:selected', $(obj).closest('tr')).val(),
        "group_id": $('#code_id option:selected', $(obj).closest('tr')).val()
      }
    },
    success: function(data) { $(obj).closest('tr').html(data); }
  });
}

function save_allocations(obj) {
  $.ajax({
    type: 'PUT',
    url: $(obj).attr('save-link') + '.json',
    data: {
      "multiple": "yes",
      "allocation": {
        "status": $('#allocations_manage_selected #status_id').val(),
        "group_id": $('#allocations_manage_selected #group_id').val()
      }
    },
    success: function(data) {
      if (data.status = 'ok') {
        $(window).attr("location", '<%= enrollments_allocations_path(:status => params[:status]) %>');
      } else {
        alert('<%= t(:allocation_manage_enrollment_unsuccessful_update) %>');
      }
    }
  });
}
