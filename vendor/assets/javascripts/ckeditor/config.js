CKEDITOR.on( 'dialogDefinition', function( ev ) {
  var dialogName       = ev.data.name; // Recupera o nome da janela
  var dialogDefinition = ev.data.definition; // Recupera dados da janela

  if ( dialogName == 'link' ) { // Se for a janela de "Link"
    dialogDefinition.removeContents('advanced'); // Remove aba de configurações avançadas

    var target = ev.data.definition.getContents('target');
    var options = target.get('linkTargetType').items;
    for (var i = options.length-1; i >= 0; i--) {
        var label = options[i][0];
        if (!label.match(/_blank/i)) {
            options.splice(i, 1);
        }
    }
    var targetField = target.get( 'linkTargetType' );
    targetField['default'] = '_blank';

    //    var infoTab = dialogDefinition.getContents( 'target'); // Recupera as informações da aba de destino do link
    //    infoTab.elements[0].children[0].default = '_blank'; // Seta como o padrão sendo "_blank"
  }
});