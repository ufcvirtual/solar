/*
 * jQuery dropdown: A simple dropdown plugin
 *
 * Inspired by Bootstrap: http://twitter.github.com/bootstrap/javascript.html#dropdowns
 *
 * Copyright 2013 Cory LaViska for A Beautiful Site, LLC. (http://abeautifulsite.net/)
 *
 * Dual licensed under the MIT / GPL Version 2 licenses
 *
*/
if(jQuery) (function($) {

  $.extend($.fn, {
    dropdown: function(method, data) {
      switch( method ) {
        case 'hide':
          hide();
          return $(this);
        case 'attach':
          return $(this).attr('data-dropdown', data);
        case 'detach':
          hide();
          return $(this).removeAttr('data-dropdown');
        case 'disable':
          return $(this).addClass('dropdown-disabled');
        case 'enable':
          hide();
          return $(this).removeClass('dropdown-disabled');
      }
    }
  });

  function show(event) {
    var trigger = $(this),
      dropdown = $(trigger.attr('data-dropdown')),
      isOpen = trigger.hasClass('dropdown-open');

    // In some cases we don't want to show it
    if( trigger !== event.target && $(event.target).hasClass('dropdown-ignore') ) return;

    event.preventDefault();
    event.stopPropagation();
    hide();

    if( isOpen || trigger.hasClass('dropdown-disabled') ) return;


    // Show it
    trigger.addClass('dropdown-open');
    dropdown
      .data('dropdown-trigger', trigger)
      .show();

    // Position it
    position();

    // Trigger the show callback
    dropdown
      .trigger('show', {
        dropdown: dropdown,
        trigger: trigger
      });

    var div = $(this).parent().find($(this).data('dropdown')).first();
      if(!$(div).data('focus')){
        $(div).find('h2').attr("tabindex", "0");
        $(div).find('h2').focus();
        $(div).data('focus', true);
      }

    $('.dropdown').on('keyup',(e) => {
      var code = e.keyCode || e.which;
      if(!div.data('focus')){
        if (code == '9'){
          $('h2:first', div).attr("tabindex", "0");
          $('h2:first', div).focus();
          div.data('focus', true);
        }
      }
    });
  }

  function hide(event) {
    // In some cases we don't hide them
    var targetGroup = event ? $(event.target).parents().andSelf() : null;

    // Are we clicking anywhere in a dropdown?
    if( targetGroup && targetGroup.is('.dropdown') ) {
      // Is it a dropdown menu?
      if( targetGroup.is('.dropdown-menu') ) {
        // Did we click on an option? If so close it.
        if( !targetGroup.is('A') ) return;
      } else {
        // Nope, it's a panel. Leave it open.
        return;
      }
    }
    
    // Hide any dropdown that may be showing
    $(document).find('.dropdown:visible').each( function() {
      if(!!$(this).data('focus')){
        var parent = $(this).parents().eq(8);
        var id = $(this).prop('id');
        var div = $(parent).find("[data-dropdown='#"+id+"']").first();
        $(div).attr("tabindex", "0");
        $(div).focus();
        $(this).data('focus', false);
      }

      var dropdown = $(this);
      dropdown
        .hide()
        .removeData('dropdown-trigger')
        .trigger('hide', { dropdown: dropdown });
    });



    // Remove all dropdown-open classes
    $(document).find('.dropdown-open').removeClass('dropdown-open');
  }

  function position() {
    var dropdown = $('.dropdown:visible').eq(0),
      trigger = dropdown.data('dropdown-trigger'),
      hOffset = trigger ? parseInt(trigger.attr('data-horizontal-offset') || 0) : null,
      vOffset = trigger ? parseInt(trigger.attr('data-vertical-offset') || 0) : null;

    if( dropdown.length === 0 || !trigger ) return;

    // Position the dropdown relative-to-parent or relative-to-document
    dropdown.css({
      left: dropdown.hasClass('dropdown-anchor-right') ?
        trigger.position().left - (dropdown.outerWidth(true) - trigger.outerWidth(true)) - parseInt(trigger.css('margin-right')) + hOffset :
        trigger.position().left + parseInt(trigger.css('margin-left')) + hOffset,
      top: trigger.position().top + trigger.outerHeight(true) - parseInt(trigger.css('margin-top')) + vOffset
    });
  }

  $(function() {
    $(document).on('click.dropdown', '[data-dropdown]', show);
    $(document).on('click.dropdown', hide);
    $(window).on('resize', position);
  });


})(jQuery);
