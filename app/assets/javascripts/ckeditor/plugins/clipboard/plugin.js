/**
 * @license Copyright (c) 2003-2014, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.md or http://ckeditor.com/license
 */
/**
 * @ignore
 * File overview: Clipboard support.
 */
//
// EXECUTION FLOWS:
// -- CTRL+C
//		* browser's default behaviour
// -- CTRL+V
//		* listen onKey (onkeydown)
//		* simulate 'beforepaste' for non-IEs on editable
//		* simulate 'paste' for Fx2/Opera on editable
//		* listen 'onpaste' on editable ('onbeforepaste' for IE)
//		* fire 'beforePaste' on editor
//		* !canceled && getClipboardDataByPastebin
//		* fire 'paste' on editor
//		* !canceled && fire 'afterPaste' on editor
// -- CTRL+X
//		* listen onKey (onkeydown)
//		* fire 'saveSnapshot' on editor
//		* browser's default behaviour
//		* deferred second 'saveSnapshot' event
// -- Copy command
//		* tryToCutCopy
//			* execCommand
//		* !success && alert
// -- Cut command
//		* fixCut
//		* tryToCutCopy
//			* execCommand
//		* !success && alert
// -- Paste command
//		* fire 'paste' on editable ('beforepaste' for IE)
//		* !canceled && execCommand 'paste'
//		* !success && fire 'pasteDialog' on editor
// -- Paste from native context menu & menubar
//		(Fx & Webkits are handled in 'paste' default listner.
//		Opera cannot be handled at all because it doesn't fire any events
//		Special treatment is needed for IE, for which is this part of doc)
//		* listen 'onpaste'
//		* cancel native event
//		* fire 'beforePaste' on editor
//		* !canceled && getClipboardDataByPastebin
//		* execIECommand( 'paste' ) -> this fires another 'paste' event, so cancel it
//		* fire 'paste' on editor
//		* !canceled && fire 'afterPaste' on editor
//
//
// PASTE EVENT - PREPROCESSING:
// -- Possible dataValue types: auto, text, html.
// -- Possible dataValue contents:
//		* text (possible \n\r)
//		* htmlified text (text + br,div,p - no presentional markup & attrs - depends on browser)
//		* html
// -- Possible flags:
//		* htmlified - if true then content is a HTML even if no markup inside. This flag is set
//			for content from editable pastebins, because they 'htmlify' pasted content.
//
// -- Type: auto:
//		* content: htmlified text ->	filter, unify text markup (brs, ps, divs), set type: text
//		* content: html ->				filter, set type: html
// -- Type: text:
//		* content: htmlified text ->	filter, unify text markup
//		* content: html ->				filter, strip presentional markup, unify text markup
// -- Type: html:
//		* content: htmlified text ->	filter, unify text markup
//		* content: html ->				filter
//
// -- Phases:
//		* filtering (priorities 3-5) - e.g. pastefromword filters
//		* content type sniffing (priority 6)
//		* markup transformations for text (priority 6)
//
"use strict";(function(){function e(e){function s(){function t(t,n,r,i,s){var o=e.lang.clipboard[n];e.addCommand(n,r),e.ui.addButton&&e.ui.addButton(t,{label:o,command:n,toolbar:"clipboard,"+i}),e.addMenuItems&&e.addMenuItem(n,{label:o,command:n,group:"clipboard",order:s})}t("Cut","cut",a("cut"),10,1),t("Copy","copy",a("copy"),20,4),t("Paste","paste",f(),30,8)}function o(){e.on("key",g),e.on("contentDom",u),e.on("selectionChange",function(e){r=e.data.selection.getRanges()[0].checkReadOnly(),b()}),e.contextMenu&&e.contextMenu.addListener(function(e,t){return r=t.getRanges()[0].checkReadOnly(),{cut:w("cut"),copy:w("copy"),paste:w("paste")}})}function u(){var r=e.editable();r.on(i,function(e){if(CKEDITOR.env.ie&&t)return;y(e)}),CKEDITOR.env.ie&&r.on("paste",function(t){if(n)return;l(),t.data.preventDefault(),y(t),h("paste")||e.openDialog("paste")}),CKEDITOR.env.ie&&(r.on("contextmenu",c,null,null,0),r.on("beforepaste",function(e){e.data&&!e.data.$.ctrlKey&&c()},null,null,0)),r.on("beforecut",function(){!t&&d(e)});var s;r.attachListener(CKEDITOR.env.ie?r:e.document.getDocumentElement(),"mouseup",function(){s=setTimeout(function(){b()},0)}),e.on("destroy",function(){clearTimeout(s)}),r.on("keyup",b)}function a(t){return{type:t,canUndo:t=="cut",startDisabled:!0,exec:function(t){function n(t){if(CKEDITOR.env.ie)return h(t);try{return e.document.$.execCommand(t,!1,null)}catch(n){return!1}}this.type=="cut"&&d();var r=n(this.type);return r||alert(e.lang.clipboard[this.type+"Error"]),r}}}function f(){return{canUndo:!1,async:!0,exec:function(e,t){var n=function(t,n){t&&p(t.type,t.dataValue,!!n),e.fire("afterCommandExec",{name:"paste",command:r,returnValue:!!t})},r=this;typeof t=="string"?n({type:"auto",dataValue:t},1):e.getClipboardData(n)}}}function l(){n=1,setTimeout(function(){n=0},100)}function c(){t=1,setTimeout(function(){t=0},10)}function h(t){var n=e.document,r=n.getBody(),i=!1,s=function(){i=!0};return r.on(t,s),(CKEDITOR.env.version>7?n.$:n.$.selection.createRange()).execCommand(t),r.removeListener(t,s),i}function p(t,n,r){var i={type:t};return r&&e.fire("beforePaste",i)===!1?!1:n?(i.dataValue=n,e.fire("paste",i)):!1}function d(){if(!CKEDITOR.env.ie||CKEDITOR.env.quirks)return;var t=e.getSelection(),n,r,i;t.getType()==CKEDITOR.SELECTION_ELEMENT&&(n=t.getSelectedElement())&&(r=t.getRanges()[0],i=e.document.createText(""),i.insertBefore(n),r.setStartBefore(i),r.setEndAfter(n),t.selectRanges([r]),setTimeout(function(){n.getParent()&&(i.remove(),t.selectElement(n))},0))}function v(t,n){var r=e.document,i=e.editable(),s=function(e){e.cancel()},o=CKEDITOR.env.gecko&&CKEDITOR.env.version<=10902,u;if(r.getById("cke_pastebin"))return;var a=e.getSelection(),f=a.createBookmarks(),l=new CKEDITOR.dom.element((CKEDITOR.env.webkit||i.is("body"))&&!CKEDITOR.env.ie&&!CKEDITOR.env.opera?"body":"div",r);l.setAttributes({id:"cke_pastebin","data-cke-temp":"1"}),CKEDITOR.env.opera&&l.appendBogus();var c=0,h,p=r.getWindow();o?(l.insertAfter(f[0].startNode),l.setStyle("display","inline")):(CKEDITOR.env.webkit?(i.append(l),l.addClass("cke_editable"),i.is("body")||(i.getComputedStyle("position")!="static"?h=i:h=CKEDITOR.dom.element.get(i.$.offsetParent),c=h.getDocumentPosition().y)):i.getAscendant(CKEDITOR.env.ie||CKEDITOR.env.opera?"body":"html",1).append(l),l.setStyles({position:"absolute",top:p.getScrollPosition().y-c+10+"px",width:"1px",height:Math.max(1,p.getViewPaneSize().height-20)+"px",overflow:"hidden",margin:0,padding:0}));var d=l.getParent().isReadOnly();d?(l.setOpacity(0),l.setAttribute("contenteditable",!0)):l.setStyle(e.config.contentsLangDirection=="ltr"?"left":"right","-1000px"),e.on("selectionChange",s,null,null,0);if(CKEDITOR.env.webkit||CKEDITOR.env.gecko)u=i.once("blur",s,null,null,-100);d&&l.focus();var v=new CKEDITOR.dom.range(l);v.selectNodeContents(l);var m=v.select();CKEDITOR.env.ie&&(u=i.once("blur",function(t){e.lockSelection(m)}));var g=CKEDITOR.document.getWindow().getScrollPosition().y;setTimeout(function(){if(CKEDITOR.env.webkit||CKEDITOR.env.opera)CKEDITOR.document[CKEDITOR.env.webkit?"getBody":"getDocumentElement"]().$.scrollTop=g;u&&u.removeListener(),CKEDITOR.env.ie&&i.focus(),a.selectBookmarks(f),l.remove();var t;CKEDITOR.env.webkit&&(t=l.getFirst())&&t.is&&t.hasClass("Apple-style-span")&&(l=t),e.removeListener("selectionChange",s),n(l.getHtml())},0)}function m(){if(CKEDITOR.env.ie){e.focus(),l();var t=e.focusManager;t.lock();if(e.editable().fire(i)&&!h("paste"))return t.unlock(),!1;t.unlock()}else try{if(e.editable().fire(i)&&!e.document.$.execCommand("Paste",!1,null))throw 0}catch(n){return!1}return!0}function g(t){if(e.mode!="wysiwyg")return;switch(t.data.keyCode){case CKEDITOR.CTRL+86:case CKEDITOR.SHIFT+45:var n=e.editable();l(),!CKEDITOR.env.ie&&n.fire("beforepaste"),(CKEDITOR.env.opera||CKEDITOR.env.gecko&&CKEDITOR.env.version<10900)&&n.fire("paste");return;case CKEDITOR.CTRL+88:case CKEDITOR.SHIFT+46:e.fire("saveSnapshot"),setTimeout(function(){e.fire("saveSnapshot")},50)}}function y(t){var n={type:"auto"},r=e.fire("beforePaste",n);v(t,function(e){e=e.replace(/<span[^>]+data-cke-bookmark[^<]*?<\/span>/ig,""),r&&p(n.type,e,0,1)})}function b(){if(e.mode!="wysiwyg")return;var t=w("paste");e.getCommand("cut").setState(w("cut")),e.getCommand("copy").setState(w("copy")),e.getCommand("paste").setState(t),e.fire("pasteState",t)}function w(t){if(r&&t in{paste:1,cut:1})return CKEDITOR.TRISTATE_DISABLED;if(t=="paste")return CKEDITOR.TRISTATE_OFF;var n=e.getSelection(),i=n.getRanges(),s=n.getType()==CKEDITOR.SELECTION_NONE||i.length==1&&i[0].collapsed;return s?CKEDITOR.TRISTATE_DISABLED:CKEDITOR.TRISTATE_OFF}var t=0,n=0,r=0,i=CKEDITOR.env.ie?"beforepaste":"paste";o(),s(),e.getClipboardData=function(t,n){function o(e){e.removeListener(),e.cancel(),n(e.data)}function u(e){e.removeListener(),r=!0,i=e.data.type}function a(e){e.removeListener(),e.cancel(),s=!0,n({type:i,dataValue:e.data})}function f(){this.customTitle=t&&t.title}var r=!1,i="auto",s=!1;n||(n=t,t=null),e.on("paste",o,null,null,0),e.on("beforePaste",u,null,null,1e3),m()===!1&&(e.removeListener("paste",o),r&&e.fire("pasteDialog",f)?(e.on("pasteDialogCommit",a),e.on("dialogHide",function(e){e.removeListener(),e.data.removeListener("pasteDialogCommit",a),setTimeout(function(){s||n(null)},10)})):n(null))}}function t(e){if(CKEDITOR.env.webkit){if(!e.match(/^[^<]*$/g)&&!e.match(/^(<div><br( ?\/)?><\/div>|<div>[^<]*<\/div>)*$/gi))return"html"}else if(CKEDITOR.env.ie){if(!e.match(/^([^<]|<br( ?\/)?>)*$/gi)&&!e.match(/^(<p>([^<]|<br( ?\/)?>)*<\/p>|(\r\n))*$/gi))return"html"}else{if(!CKEDITOR.env.gecko&&!CKEDITOR.env.opera)return"html";if(!e.match(/^([^<]|<br( ?\/)?>)*$/gi))return"html"}return"htmlifiedtext"}function n(e,t){function n(e){return CKEDITOR.tools.repeat("</p><p>",~~(e/2))+(e%2==1?"<br>":"")}return t=t.replace(/\s+/g," ").replace(/> +</g,"><").replace(/<br ?\/>/gi,"<br>"),t=t.replace(/<\/?[A-Z]+>/g,function(e){return e.toLowerCase()}),t.match(/^[^<]$/)?t:(CKEDITOR.env.webkit&&t.indexOf("<div>")>-1&&(t=t.replace(/^(<div>(<br>|)<\/div>)(?!$|(<div>(<br>|)<\/div>))/g,"<br>").replace(/^(<div>(<br>|)<\/div>){2}(?!$)/g,"<div></div>"),t.match(/<div>(<br>|)<\/div>/)&&(t="<p>"+t.replace(/(<div>(<br>|)<\/div>)+/g,function(e){return n(e.split("</div><div>").length+1)})+"</p>"),t=t.replace(/<\/div><div>/g,"<br>"),t=t.replace(/<\/?div>/g,"")),(CKEDITOR.env.gecko||CKEDITOR.env.opera)&&e.enterMode!=CKEDITOR.ENTER_BR&&(CKEDITOR.env.gecko&&(t=t.replace(/^<br><br>$/,"<br>")),t.indexOf("<br><br>")>-1&&(t="<p>"+t.replace(/(<br>){2,}/g,function(e){return n(e.length/4)})+"</p>")),s(e,t))}function r(e){var t=new CKEDITOR.htmlParser.filter,n={blockquote:1,dl:1,fieldset:1,h1:1,h2:1,h3:1,h4:1,h5:1,h6:1,ol:1,p:1,table:1,ul:1},r=CKEDITOR.tools.extend({br:0},CKEDITOR.dtd.$inline),i={p:1,br:1,"cke:br":1},s=CKEDITOR.dtd,o=CKEDITOR.tools.extend({area:1,basefont:1,embed:1,iframe:1,map:1,object:1,param:1},CKEDITOR.dtd.$nonBodyContent,CKEDITOR.dtd.$cdata),u=function(e){delete e.name,e.add(new CKEDITOR.htmlParser.text(" "))},a=function(e){var t=e,n,r;while((t=t.next)&&t.name&&t.name.match(/^h\d$/)){n=new CKEDITOR.htmlParser.element("cke:br"),n.isEmpty=!0,e.add(n);while(r=t.children.shift())e.add(r)}};return t.addRules({elements:{h1:a,h2:a,h3:a,h4:a,h5:a,h6:a,img:function(e){var t=CKEDITOR.tools.trim(e.attributes.alt||""),n=" ";return t&&!t.match(/(^http|\.(jpe?g|gif|png))/i)&&(n=" ["+t+"] "),new CKEDITOR.htmlParser.text(n)},td:u,th:u,$:function(e){var t=e.name,u;if(o[t])return!1;e.attributes={};if(t=="br")return e;if(n[t])e.name="p";else if(r[t])delete e.name;else if(s[t]){u=new CKEDITOR.htmlParser.element("cke:br"),u.isEmpty=!0;if(CKEDITOR.dtd.$empty[t])return u;e.add(u,0),u=u.clone(),u.isEmpty=!0,e.add(u),delete e.name}return i[e.name]||delete e.name,e}}},{applyToAll:!0}),t}function i(e,t,n){var r=new CKEDITOR.htmlParser.fragment.fromHtml(t),i=new CKEDITOR.htmlParser.basicWriter;r.writeHtml(i,n),t=i.getHtml(),t=t.replace(/\s*(<\/?[a-z:]+ ?\/?>)\s*/g,"$1").replace(/(<cke:br \/>){2,}/g,"<cke:br />").replace(/(<cke:br \/>)(<\/?p>|<br \/>)/g,"$2").replace(/(<\/?p>|<br \/>)(<cke:br \/>)/g,"$1").replace(/<(cke:)?br( \/)?>/g,"<br>").replace(/<p><\/p>/g,"");var o=0;return t=t.replace(/<\/?p>/g,function(e){if(e=="<p>"){if(++o>1)return"</p><p>"}else if(--o>0)return"</p><p>";return e}).replace(/<p><\/p>/g,""),s(e,t)}function s(e,t){return e.enterMode==CKEDITOR.ENTER_BR?t=t.replace(/(<\/p><p>)+/g,function(e){return CKEDITOR.tools.repeat("<br>",e.length/7*2)}).replace(/<\/?p>/g,""):e.enterMode==CKEDITOR.ENTER_DIV&&(t=t.replace(/<(\/)?p>/g,"<$1div>")),t}CKEDITOR.plugins.add("clipboard",{requires:"dialog",lang:"af,ar,bg,bn,bs,ca,cs,cy,da,de,el,en,en-au,en-ca,en-gb,eo,es,et,eu,fa,fi,fo,fr,fr-ca,gl,gu,he,hi,hr,hu,id,is,it,ja,ka,km,ko,ku,lt,lv,mk,mn,ms,nb,nl,no,pl,pt,pt-br,ro,ru,si,sk,sl,sq,sr,sr-latn,sv,th,tr,ug,uk,vi,zh,zh-cn",icons:"copy,copy-rtl,cut,cut-rtl,paste,paste-rtl",hidpi:!0,init:function(s){var o;e(s),CKEDITOR.dialog.add("paste",CKEDITOR.getUrl(this.path+"dialogs/paste.js")),s.on("paste",function(e){var t=e.data.dataValue,n=CKEDITOR.dtd.$block;t.indexOf("Apple-")>-1&&(t=t.replace(/<span class="Apple-converted-space">&nbsp;<\/span>/gi," "),e.data.type!="html"&&(t=t.replace(/<span class="Apple-tab-span"[^>]*>([^<]*)<\/span>/gi,function(e,t){return t.replace(/\t/g,"&nbsp;&nbsp; &nbsp;")})),t.indexOf('<br class="Apple-interchange-newline">')>-1&&(e.data.startsWithEOL=1,e.data.preSniffing="html",t=t.replace(/<br class="Apple-interchange-newline">/,"")),t=t.replace(/(<[^>]+) class="Apple-[^"]*"/gi,"$1"));if(t.match(/^<[^<]+cke_(editable|contents)/i)){var r,i,s=new CKEDITOR.dom.element("div");s.setHtml(t);while(s.getChildCount()==1&&(r=s.getFirst())&&r.type==CKEDITOR.NODE_ELEMENT&&(r.hasClass("cke_editable")||r.hasClass("cke_contents")))s=i=r;i&&(t=i.getHtml().replace(/<br>$/i,""))}CKEDITOR.env.ie?t=t.replace(/^&nbsp;(?: |\r\n)?<(\w+)/g,function(t,r){return r.toLowerCase()in n?(e.data.preSniffing="html","<"+r):t}):CKEDITOR.env.webkit?t=t.replace(/<\/(\w+)><div><br><\/div>$/,function(t,r){return r in n?(e.data.endsWithEOL=1,"</"+r+">"):t}):CKEDITOR.env.gecko&&(t=t.replace(/(\s)<br>$/,"$1")),e.data.dataValue=t},null,null,3),s.on("paste",function(e){var u=e.data,a=u.type,f=u.dataValue,l,c=s.config.clipboard_defaultContentType||"html";a=="html"||u.preSniffing=="html"?l="html":l=t(f),l=="htmlifiedtext"?f=n(s.config,f):a=="text"&&l=="html"&&(f=i(s.config,f,o||(o=r(s)))),u.startsWithEOL&&(f='<br data-cke-eol="1">'+f),u.endsWithEOL&&(f+='<br data-cke-eol="1">'),a=="auto"&&(a=l=="html"||c=="html"?"html":"text"),u.type=a,u.dataValue=f,delete u.preSniffing,delete u.startsWithEOL,delete u.endsWithEOL},null,null,6),s.on("paste",function(e){var t=e.data;s.insertHtml(t.dataValue,t.type),setTimeout(function(){s.fire("afterPaste")},0)},null,null,1e3),s.on("pasteDialog",function(e){setTimeout(function(){s.openDialog("paste",e.data)},0)})}})})();