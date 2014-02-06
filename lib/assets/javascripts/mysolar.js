/****************************************************
 * Agenda
 ****************************************************/

// Destaca dias que possuem algum evento
var highlightDay = function(date, dates_with_events) {

  // recuperando as datas dos eventos correntes
  for (var idx in dates_with_events) {
    // esperando o formato yyyy-mm-dd
    var date_split = dates_with_events[idx].split('-');
    var ano = date_split[0];
    var mes = (date_split[1] - 1); // a contagem do mes começa com 0
    var dia = date_split[2];
    var date_schedule = new Date(ano, mes, dia);

    if (date.toString() == date_schedule.toString())
      return [true, 'highlight-date-mark'];
  }

  return [true, ''];
}

// Quando ocorre um evento de mudanca de dia, os eventos
// para o novo dia devem ser exibidas
var changeDate = function(dateText, url_for_agenda) {
  $.get(url_for_agenda, {
    date: dateText,
    list_all_schedule: true
  },
  function(response) {
    $('.calendar_events').html(response);
    $('.schedule_link_more').remove();
  });
}

// Exibe a agenda no portlet
// Obs.: esta funcao deve permanecer global
function showAgenda(dates_with_events) {
  // url para pegar os eventos
  var url_for_agenda = $('#agenda').attr('url_for');
  // carregando eventos do dia atual
  var today = new Date();
  changeDate(today.toGMTString(), url_for_agenda);
  // passando o locale do sistema para o javascript
  var locale = $.datepicker.regional[global_config.locale.I18n];

  $("#agenda").datepicker({
    option: locale,
    dateFormat: global_config.locale.dateFormat,
    onSelect: function(dateText, inst) {
      changeDate(dateText, url_for_agenda);
    },
    beforeShowDay: function(date){
      return highlightDay(date, dates_with_events);
    }
  });
}
