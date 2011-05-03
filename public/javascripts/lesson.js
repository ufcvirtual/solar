function show_lesson (address){
    if (address!=''){
        //testando efeito
        //$("#lesson_area").show(500);
        $("#lesson_area").fadeIn(1000);
        //$("#lesson_area").slideDown(1000);

        //remove pra nao ficar duplicado caso alguma ja tenha sido aberta
        $("#lesson_address").remove();
        $("#lesson_content").append("<div id='lesson_address'></div>");
        $("#lesson_address").append("<iframe class=lesson_frame src='"+address+"'></iframe>");
    }
}

function hide_lesson (){
    //testando efeito
    //$("#lesson_area").hide(500);
    $("#lesson_area").fadeOut(1000);
    //$("#lesson_area").slideUp(1000);
}
