/* 
 Equation Editor Plugin for CKEditor v4
 Version 1.4

 This plugin allows equations to be created and edited from within CKEditor.
 For more information goto: http://www.codecogs.com/latex/integration/ckeditor_v4/install.php
 
 Copyright CodeCogs 2006-2013
 Written by Will Bateman.
*/
CKEDITOR.plugins.add("eqneditor",{availableLangs:{en:1},lang:"pt-br",requires:["dialog"],icons:"eqneditor",init:function(e){var t="latex.codecogs.com",n="https:"==document.location.protocol?"https://":"http://";CKEDITOR.scriptLoader.load([n+t+"/js/eq_config.js",n+t+"/js/eq_editor-lite-17.js"]);var r=document.createElement("link");r.setAttribute("rel","stylesheet"),r.setAttribute("type","text/css"),r.setAttribute("href","/assets/ckeditor/plugins/eqneditor/equation-embed.css"),document.getElementsByTagName("head")[0].appendChild(r);var i="eqneditorDialog";e.addCommand(i,new CKEDITOR.dialogCommand(i,{allowedContent:"img[src,alt]",requiredContent:"img[src,alt]"})),CKEDITOR.dialog.add(i,this.path+"dialogs/eqneditor.js"),e.ui.addButton("EqnEditor",{label:e.lang.eqneditor.toolbar,command:i,icon:this.path+"icons/eqneditor.png",toolbar:"insert"}),e.contextMenu&&(e.addMenuGroup(e.lang.eqneditor.menu),e.addMenuItem("eqneditor",{label:e.lang.eqneditor.edit,icon:this.path+"icons/eqneditor.png",command:i,group:e.lang.eqneditor.menu}),e.contextMenu.addListener(function(e){var t={};if(e.getAscendant("img",!0)){var n=e.getAttribute("src").match(/(gif|svg)\.latex\?(.*)/);if(n!=null)return t.eqneditor=CKEDITOR.TRISTATE_OFF,t}})),e.on("doubleclick",function(e){var t=e.data.element;if(t&&t.is("img")){var n=t.getAttribute("src").match(/(gif|svg)\.latex\?(.*)/);n!=null&&(e.data.dialog=i,e.cancelBubble=!0,e.returnValue=!1,e.stop())}},null,null,1)}});