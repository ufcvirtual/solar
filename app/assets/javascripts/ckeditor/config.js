CKEDITOR.on( 'dialogDefinition', function( ev ) {
  var dialogName       = ev.data.name; // Recupera o nome da janela
  var dialogDefinition = ev.data.definition; // Recupera dados da janela

  if ( dialogName == 'link' ) { // Se for a janela de "Link"
    dialogDefinition.removeContents('advanced'); // Remove aba de configurações avançadas
    var infoTab = dialogDefinition.getContents( 'target'); // Recupera as informações da aba de destino do link
    infoTab.elements[0].children[0].default = '_blank'; // Seta como o padrão sendo "_blank"
  }
});