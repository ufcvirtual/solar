function show_lesson (address){    
    //$("#lesson_area").show(500);
    $("#lesson_area").fadeIn(1000);
    //$("#lesson_area").slideDown(1000);

    //$("#lesson_content_header").after("<iframe class=lesson_frame src='"+address+"'></iframe>");
    $("#lesson_address").remove();
    $("#lesson_content_header").after("<div id='lesson_address'></div>");
    $("#lesson_address").append("<iframe class=lesson_frame src='"+address+"'></iframe>");
}

function hide_lesson (){
    //$("#lesson_area").hide(500);
    $("#lesson_area").fadeOut(1000);
    //$("#lesson_area").slideUp(1000);
}
