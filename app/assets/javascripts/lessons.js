lesson_cookie_id = "_ufc_solar20_lesson_opened";

function open_lesson(path, url) {
  $(".show_lesson .content").attr("data-url", url);

  var home_tab = $(".mysolar_unit_active_tab.general_context").length;
  if (!home_tab && $.cookie(lesson_cookie_id)){
    $.cookie(lesson_cookie_id, url, { path: '/' });
  }

  $("iframe#content_lesson").prop("src", path);
}

function maximize_lesson(obj) {
  if (!$.cookie(lesson_cookie_id))
    return;

  $(obj).nice_open_lesson({ href: $.cookie(lesson_cookie_id) });
  event.preventDefault();
}

function minimize_lesson() {
  var home_tab = $(".mysolar_unit_active_tab.general_context").length;
  if (!home_tab) {
    // save cookie with the new url
    var lesson_URL = $(".fancybox-iframe").contents().find(".show_lesson .content").data("url");
    $.cookie(lesson_cookie_id, lesson_URL);

    $(".fancybox-skin").effect( "transfer", { to: $("#mysolar_open_lesson") }, 750 ); // transfer effect
    $("#mysolar_open_lesson button").removeClass("disabled");
  }
  $.fancybox.close();
}

function close_lesson() {
  $("#mysolar_open_lesson button").addClass("disabled");
  $.removeCookie(lesson_cookie_id);
}
