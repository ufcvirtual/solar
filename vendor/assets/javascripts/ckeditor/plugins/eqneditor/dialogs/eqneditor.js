/* 
 Equation Editor Plugin for CKEditor v4
 Version 1.4

 This plugin allows equations to be created and edited from within CKEditor.
 For more information goto: http://www.codecogs.com/latex/integration/ckeditor_v4/install.php
 
 Copyright CodeCogs 2006-2013
 Written by Will Bateman.
 */
CKEDITOR.dialog.add( 'eqneditorDialog', function(editor)
{	
	var http = ('https:' == document.location.protocol ? 'https://' : 'http://');
	return {
		title : editor.lang.eqneditor.title,
		minWidth : 570,
		minHeight : 430,
		resizable: CKEDITOR.DIALOG_RESIZE_NONE,
		contents : [
		{
			id : 'CCEquationEditor',
			label : 'EqnEditor',
			elements : [
			{
				type: 'html',
				html: '<div id="CCtoolbar"></div>',	
				style: 'margin-top:-9px'
			},
			{
				type: 'html',
				html: '<label>Cor da fonte</label>'
			},
			{
				type: 'html',
				html: '<label>Fonte</label>'
			},
			{
				type: 'html',
				html: '<label>Tamanho da fonte</label>'
			},
			{
				type: 'html',
				html: '<label>Cor de fundo</label>'
			},
			{
				type: 'html',
				html: '<label for="CClatex">Editar Equação (LaTeX):</label>'
			},
			{
				type: 'html',
				html: '<textarea id="CClatex" rows="5"></textarea>',
				style:'border:1px solid #8fb6bd; width:540px; font-size:16px; padding:5px; background-color:#ffc'
			},
			{
				type: 'html',
				html: '<label for="CCequation">Visualizar:</label>'		
			},
			{
				type: 'button',
				id: 'barra',
				label: '|',
				onClick: function()
				{
					function insertAtCaret(areaId,text) {
						var txtarea = document.getElementById(areaId);
						var scrollPos = txtarea.scrollTop;
						var strPos = 0;
						var br = ((txtarea.selectionStart || txtarea.selectionStart == '0') ? 
							"ff" : (document.selection ? "ie" : false ) );
						if (br == "ie") { 
							txtarea.focus();
							var range = document.selection.createRange();
							range.moveStart ('character', -txtarea.value.length);
							strPos = range.text.length;
						}
						else if (br == "ff") {
							strPos = txtarea.selectionStart;
						}
						var front = (txtarea.value).substring(0,strPos);  
						var back = (txtarea.value).substring(strPos,txtarea.value.length); 
						txtarea.value=front+text+back;
						strPos = strPos + text.length;
						if (br == "ie") { 
							txtarea.focus();
							var range = document.selection.createRange();
							range.moveStart ('character', -txtarea.value.length);
							range.moveStart ('character', strPos);
							range.moveEnd ('character', 0);
							range.select();
						}
						else if (br == "ff") {
							txtarea.selectionStart = strPos;
							txtarea.selectionEnd = strPos;
							txtarea.focus();
						}
						txtarea.scrollTop = scrollPos;
					}

					insertAtCaret('CClatex','\\'+'Bigg|_ ^ {}');	
				}
			}, 
			{
				type :'html',
				html: '<div style="position:absolute; left:5px; bottom:0; z-index:999"><a href="http://www.codecogs.com" target="_blank">CodeCogs &copy; 2007-2013</a></div><img id="CCequation" src="'+http+'www.codecogs.com/images/spacer.gif" />'					
			}
			]
		}
		],
		onLoad : function() {
			EqEditor.embed('CCtoolbar','','efull');
			EqEditor.add(new EqTextArea('CCequation', 'CClatex'),false);
		},
		onShow : function() {
			var dialog = this,
			sel = editor.getSelection(),
			image = sel.getStartElement().getAscendant('img',true);

			// has the users selected an equation. Make sure we have the image element, include itself		
			if(image) 
			{
				var sName = image.getAttribute('src').match( /(gif|svg)\.latex\?(.*)/ );
				if(sName!=null) {
					EqEditor.getTextArea().setText(sName[2]);
				}
				dialog.insertMode = true;
			}
			
			// set-up the field values based on selected or newly created image
			dialog.setupContent( dialog.image );
		},
		
		onOk : function() {
			var eqn = editor.document.createElement( 'img' );
			eqn.setAttribute( 'alt', EqEditor.getTextArea().getLaTeX());
			eqn.setAttribute( 'src', EqEditor.getTextArea().exportEquation('urlencoded'));
			editor.insertElement(eqn);
		}
	};
});

