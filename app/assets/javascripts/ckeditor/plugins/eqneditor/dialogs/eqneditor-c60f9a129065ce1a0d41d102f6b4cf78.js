/* 
 Equation Editor Plugin for CKEditor v4
 Version 1.4

 This plugin allows equations to be created and edited from within CKEditor.
 For more information goto: http://www.codecogs.com/latex/integration/ckeditor_v4/install.php
 
 Copyright CodeCogs 2006-2013
 Written by Will Bateman.
 
 Special Thanks to:
  - Kyle Jones for a fix to allow multiple editor to load on one page
*/
window.CCounter=0,CKEDITOR.dialog.add("eqneditorDialog",function(e){var t="https:"==document.location.protocol?"https://":"http://";return window.CCounter++,{title:e.lang.eqneditor.title,minWidth:567,minHeight:430,resizable:CKEDITOR.DIALOG_RESIZE_NONE,contents:[{id:"CCEquationEditor",label:"EqnEditor",elements:[{type:"html",html:'<div id="CCtoolbar'+window.CCounter+'"></div>',style:"margin-top:-9px"},{type:"html",html:'<label for="CClatex'+window.CCounter+'">Equação (LaTeX):</label>'},{type:"html",html:'<textarea id="CClatex'+window.CCounter+'" rows="5"></textarea>',style:"border:1px solid #8fb6bd; width:540px; font-size:16px; padding:5px; background-color:#ffc"},{type:"html",html:'<label for="CCequation'+window.CCounter+'" class="lbl_font">Visualizar:</label>'},{type:"html",html:'<div style="position:absolute; left:5px; bottom:0; z-index:999"><a href="http://www.codecogs.com" target="_blank"><img src="'+t+'latex.codecogs.com/images/poweredbycc.gif" width="105" height="35" border="0" alt="Powered by CodeCogs" style="vertical-align:-4px"/></a> &nbsp; <a href="http://www.codecogs.com/latex/about.php" target="_blank">About</a> | <a href="http://www.codecogs.com/latex/popup.php" target="_blank">Install</a> | <a href="http://www.codecogs.com/pages/forums/forum_view.php?f=28" target="_blank">Forum</a> | <a href="http://www.codecogs.com" target="_blank">CodeCogs</a> &copy; 2007-2013</div><img id="CCequation'+window.CCounter+'" src="'+t+'www.codecogs.com/images/spacer.gif" />'}]}],onLoad:function(){EqEditor.embed("CCtoolbar"+window.CCounter,"","efull"),EqEditor.add(new EqTextArea("CCequation"+window.CCounter,"CClatex"+window.CCounter),!1)},onShow:function(){var t=this,n=e.getSelection(),r=n.getStartElement().getAscendant("img",!0);if(r){var i=r.getAttribute("src").match(/(gif|svg)\.latex\?(.*)/);i!=null&&EqEditor.getTextArea().setText(i[2]),t.insertMode=!0}t.setupContent(t.image)},onOk:function(){var t=e.document.createElement("img");t.setAttribute("alt",EqEditor.getTextArea().getLaTeX()),t.setAttribute("src",EqEditor.getTextArea().exportEquation("urlencoded")),e.insertElement(t),Example.add_history(EqEditor.getTextArea().getLaTeX())}}});