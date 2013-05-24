
$(function(){
  /* script da area de cadastro e login */
  $("#register-bt").click(function(){

    $(this).removeClass('inactive');
    $('#login-bt').addClass('inactive');
    $("#login-form").hide();
    $("#login-register").show();
  });

  $("#login-bt").click(function(){
    $("#login-form").show();
    $("#login-register").hide();
    $(this).removeClass('inactive');
    $('#register-bt').addClass('inactive');
  });

  /* script dos paineis de informacao */
  $(".panel .arrow").click(function(){
    $(".menu_footer a").removeClass("current_menu");
    $(".panel").fadeOut();
  });

  $(".menu_footer a.panel-link").click(function(event){
    event.preventDefault();
    var painelId = $(this).attr("href");
    $(".menu_footer a.panel-link").removeClass("current_menu");
    $("a[href="+painelId+"]").addClass("current_menu");
    $(painelId).fadeToggle(800,function(){
      $(".panel").each(function(){
        var painelOcultar = $(this).attr("id");
        var painelOcultarId = "#"+painelOcultar;
        if ( painelOcultarId != painelId ) {
          $(this).fadeOut(800);
        }
      })
    });
    $(".content", painelId).jScrollPane();
  });

  /* Passo-a-passo da página de cadastro*/
  $(".next").click(function (event) {
    event.preventDefault();

    btnParent = $(this).parents('.form-panel');
    btnParentId = $(btnParent).attr('id');
    btnParentNext = $(btnParent).next('div');
    btnParentNextId = $(btnParentNext).attr('id');

    $("#register-steps .dot").removeClass('active');
    $("#dot-"+btnParentId).addClass('done');
    $("#dot-"+btnParentNextId).addClass('active');

    $("#register-steps li").removeClass('active');
    $("#dot-"+btnParentNextId).parent('li').addClass('active');

    $(btnParent).hide();
    $(btnParentNext).show();
  });

  $(".back").click(function(event) {
    event.preventDefault();

    btnParent = $(this).parents('.form-panel');
    btnParentId = $(btnParent).attr('id');
    btnParentPrevious = $(btnParent).prev('div');
    btnParentPreviousId = $(btnParentPrevious).attr('id');

    $("#register-steps .dot").removeClass('active');
    $("#dot-"+btnParentPreviousId).removeClass('done').addClass('active');

    $("#register-steps li").removeClass('active');
    $("#dot-"+btnParentPreviousId).parent('li').addClass('active');

    $(btnParent).hide();
    $(btnParentPrevious).show();
  })


  /* Implementando método alternativo ao placeholder no IE < 9 */
  $.support.placeholder = ( 'placeholder' in document.createElement('input') );

  if( !$.support.placeholder ) {
    /* criação de um campo falso de senha, do tipo texto, para exibir o valor 'Senha' */
    var fakePassword = "<input type='text' name='fake_pass' id='fake_pass' value='Senha' style='display:none'/>"
    
    /* adicionar o input fake, ocultar o real e exibir o fake */
    $('#password').before(fakePassword);
    $("#password").hide();
    $("#fake_pass").show();

    $('#fake_pass').focus(function(){
      $(this).hide();
      $('#password').show().focus();
    });

    $('#password').blur(function(){
      if($(this).val() == ""){
          $(this).hide();
          $('#fake_pass').show();
      }
    });

    /* nos outros campos, pegar o valor do atributo placeholder e colocar como value */
    $('input[placeholder]').each(function(){
      var ph = $(this).attr('placeholder')
      $(this).val(ph).focus(function(){
        if($(this).val() == ph) $(this).val('')
      }).blur(function(){
        if(!$(this).val()) $(this).val(ph)
      })
    });
  }

  /* Menu de idiomas */
  $(document).on('click', function() {
    $(".choice-language-menu").hide(); /* oculta o menu caso clique fora dele */
  });

  $(".choice-language-menu").on('click', function(event){
    event.stopPropagation(); /* impede que o menuu seja ocultado ao clicar sobre ele */
  });

  $(".choice-language > a").on('click', function(event) {
    event.preventDefault();
    event.stopPropagation(); /* impede que o menuu seja ocultado ao clicar sobre ele */
    languageParent = $(this).parent('li');
    $('.choice-language-menu', languageParent).toggle().position({
      my: 'bottom',
      at: 'top-5',
      of: languageParent
    });
  });
});





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

// Quando ocorre um evento de mudanca de dia, as schedules
// para o novo dia devem ser exibidas
var changeDate = function(dateText, url_for_schedules) {
  $.get(url_for_schedules, {
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
  // url para pegar as schedules
  var url_for_schedules = $('#agenda').attr('url_for');
  // carregando eventos do dia atual
  var today = new Date();
  changeDate(today.toGMTString(), url_for_schedules);
  // passando o locale do sistema para o javascript
  var locale = $.datepicker.regional[global_config.locale.I18n];

  $("#agenda").datepicker({
    option: locale,
    dateFormat: global_config.locale.dateFormat,
    onSelect: function(dateText, inst) {
      changeDate(dateText, url_for_schedules);
    },
    beforeShowDay: function(date){
      return highlightDay(date, dates_with_events);
    }
  });
}
