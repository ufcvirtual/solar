function showPanel(panelId){
    //alert(panel);
    hideAll();
    $('#'+panelId).show();
    $('#'+panelId+"_button").show();
    $('#'+panelId+'_tab').css('background-color','#F7F7F7');

}
function hideAll(){
    $('#my_cadastral_data').hide();
    $('#my_personal_data').hide();
    $('#my_personal_data_button').hide();
    $('#my_cadastral_data_button').hide();

    $('#my_professional_data_tab').css('background-color','#dedede');
    $('#my_personal_data_tab').css('background-color','#dedede');
    $('#my_cadastral_data_tab').css('background-color','#dedede');
}

/*
//--------------------------------------\\
  ----------------AGENDA----------------
\\--------------------------------------//
*/

//--------------------------------------
// Destaca dias que possuem algum evento
//--------------------------------------

var highlightDay = function(date, dates_with_events) {

    // recuperando as datas dos eventos correntes
    //var all_dates_schedules_events = eval($('#date-values', $('#dates-schedules-events')).html());

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

//--------------------------------------------------------
// Quando ocorre um evento de mudanca de dia, as schedules
// para o novo dia devem ser exibidas
//--------------------------------------------------------

var changeDate = function(dateText) {
    $.get('/schedules/show', {
        date: dateText,
        list_all_schedule: true
    },
    function(response) {
        $('.calendar_events').html(response);
        $('.schedule_link_more').remove();
    });
}

//-----------------------------------------
// Exibe a agenda no portlet
// Obs.: esta funcao deve permanecer global
//-----------------------------------------

function showAgenda(dates_with_events) {
    // carregando eventos do dia atual
    var today = new Date();
    changeDate(today.toGMTString());

    var local = I18nlocale;
    var locale = $.datepicker.regional[local];
    if (local=='en')
        locale = $.datepicker.regional['en-GB'];

    $("#agenda").datepicker({
        option: locale,
        onSelect: function(dateText, inst) {
            changeDate(dateText);
        },
        beforeShowDay: function(date){
            return highlightDay(date, dates_with_events);
        }
    });
}
