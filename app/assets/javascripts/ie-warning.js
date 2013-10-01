$().ready(function(){
  $("body").append('<div id="dialog-message" title="Navegador não suportado"> \
  <p> Você está utilizando um navegador cuja <b>versão não é suportada</b>. Favor utilizar uma versão mais recente ou um dos navegadores abaixo:</p> \
  <div id="browser-list"> \
    <div id="firefox"><div class="logo"><a href="http://www.mozilla.org/firefox"><img src="assets/browser-firefox.png" width="100" height="100"></a></div><div class="version"><a href="http://www.mozilla.org/firefox">Firefox</a></div></div>\
    <div id="chrome"><div class="logo"><a href="http://chrome.google.com"><img src="assets/browser-chrome.png" width="100" height="100"></a></div><div class="version"><a href="http://chrome.google.com">Chrome</a></div></div>\
    <div id="ie"><div class="logo"><a href="https://www.microsoft.com/pt-br/download/internet-explorer-9-details.aspx"><img src="assets/browser-ie9.png" width="100" height="100"></a></div><div class="version"><a href="https://www.microsoft.com/pt-br/download/internet-explorer-9-details.aspx">Internet Explorer 9 ou superior</a></div></div>\
  </div> \
  </div>');

  $(function() {
    $( "#dialog-message" ).dialog({
      dialogClass: "no-close",
      modal: true,
      width: 500,
      height: 300
    });
  });
})