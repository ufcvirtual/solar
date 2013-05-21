CKEDITOR.editorConfig = function( config )
{
    config.toolbar =
    [
        { name: 'clipboard', items : [ 'Cut','Copy','Paste','PasteText','PasteFromWord','-','Undo','Redo' ] },
        { name: 'styles', items : [ 'Styles','Format' ] },
        { name: 'basicstyles', items : [ 'Bold','Italic','Strike','-','RemoveFormat' ] },
        { name: 'paragraph', items : [ 'NumberedList','BulletedList','-','Outdent','Indent', ] },
        { name: 'links', items : [ 'Link','Unlink' ] }
    ];
}

CKEDITOR.on( 'dialogDefinition', function( ev ) {
  var dialogName       = ev.data.name; // Recupera o nome da janela
  var dialogDefinition = ev.data.definition; // Recupera dados da janela

  if ( dialogName == 'link' ) { // Se for a janela de "Link"
    dialogDefinition.removeContents('advanced'); // Remove aba de configurações avançadas
    var infoTab = dialogDefinition.getContents( 'target'); // Recupera as informações da aba de destino do link
    infoTab.elements[0].children[0].default = '_blank'; // Seta como o padrão sendo "_blank"
  }
});