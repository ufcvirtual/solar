/**
 * @license Copyright (c) 2003-2019, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see https://ckeditor.com/legal/ckeditor-oss-license
 */

CKEDITOR.editorConfig = function( config ) {
	// Define changes to default configuration here.
	// For complete reference see:
	// https://ckeditor.com/docs/ckeditor4/latest/api/CKEDITOR_config.html

	// The toolbar groups arrangement, optimized for two toolbar rows.
	config.toolbarGroups = [
	    { name: 'clipboard',   groups: [ 'cut', 'copy', 'paste', 'pasteText', 'pasteFromWord', '-', 'undo', 'redo' ] },
	    { name: 'editing',     groups: [ 'find', 'selection', 'spellchecker' ] },
	    { name: 'links',  groups: ['link', 'unlink', 'image', 'oembed', 'smiley' ] },
	    { name: 'insert', groups: ['eqneditor' ] },
	    { name: 'forms' },
	    { name: 'tools' },
	    { name: 'document',    groups: [ 'mode', 'document', 'doctools' ] },
	    { name: 'others' },
	    '/',
	    { name: 'basicstyles', groups: [ 'basicstyles', 'cleanup', 'bold', 'italic', 'underline', 'strike', '-', 'removeformat' ] },
	    { name: 'paragraph',   groups: [ 'list', 'indent', 'blocks', 'align', 'bidi' ] },
	    { name: 'styles',   groups: [ 'styles', 'format', 'font', 'textcolor' ] },
	    { name: 'colors' },
	    { name: 'about' }
	  ];

	// Remove some buttons provided by the standard plugins, which are
	// not needed in the Standard(s) toolbar.
	config.removeButtons = 'Underline,Subscript,Superscript';

	// Set the most common block elements.
	config.format_tags = 'p;h1;h2;h3;pre';

	// Simplify the dialog windows.
	config.removeDialogTabs = 'image:advanced;link:advanced';
};
