/* *****************************************************************************
 * LightBox genérico do sistema
 * *****************************************************************************/
function showLightBoxURL(url, width, height, canClose, title){
  showLightBox('', width, height, canClose, title);

  $("#lightBoxDialogContent").load(url, function(response, status, xhr) {
    if (status == "error") {
      var msg = "Erro na aplicação.\n Por favor, aguarde alguns instantes.";//internacionalizar
      alert(msg);
    }
  });
}

function showLightBox(content, width, height, canClose, title){
  if (width == null)
    width = 500;
  if (height == null)
    height = 300;
  if (canClose == null)
    canClose = true;

  var halfWidth = Math.floor(width/2);
  var halfHeight = Math.floor(height/2);
  var modalClose = '';
  var lightBox = '';
  var dialog = '';
  var closeBt = '';

  if (canClose){
    modalClose = 'onclick="removeLightBox();" ';
    closeBt = '<div ' + modalClose + ' id="lightBoxDialogCloseBt"><i class="icon-cross-circle warning"></i></div>';
  }
  title = '<div id="lightBoxDialogTitle"><h1>'+title+'</h1></div>'
  
  removeLightBox(true);
  dialog = '<div id="lightBoxDialog" style="width:'+width+'px;max-height:'+(height+50)+'px;margin-top:-'+halfHeight+'px;margin-left:-'+halfWidth+'px;">'
  + closeBt
  + title
  + '<div id="lightBoxDialogContent">'
  + content
  + '</div>'
  lightBox = '<div id="lightBoxBackground" ' + modalClose + '>&nbsp;</div>';
  lightBox += dialog;
  $(document.body).append(lightBox);
  $("#lightBoxBackground").fadeTo("fast", 0.7, function() {
    $("#lightBoxDialog").slideDown("fast");
  });

  return false;
}

function removeLightBox(force){
  if (force == null){
    $("#lightBoxDialog").slideUp("400", function() {
      $("#lightBoxBackground").fadeOut("400", function() {
        $('#lightBoxBackground').remove();
        $('#lightBoxDialog').remove();
      });
    });
    return;
  }
  $('#lightBoxBackground').remove();
  $('#lightBoxDialog').remove();
}
