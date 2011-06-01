function show_div(origin,elementId) {    
    var posx =$('#'+origin).offset().left-2;
    var posy =$('#'+origin).offset().top+14;

    $('#'+ elementId).css({"left":posx});
    $('#'+ elementId).css({"top":posy});
    $('#'+ elementId).toggle();
}

// VER SE PRECISA...
function dropdown_menu(){
    $("#message_menu a, li a").removeAttr('title');
    $("#message_menu ul").css({display: "none"}); // Opera Fix
    $("#message_menu li").each(
        function(){
            var $sublist = $(this).find('ul');//var $sublist = $(this).find(‘ul:first’); original
            $(this).hover(function(){
            $sublist.stop().css({overflow:"hidden", height:"auto", display:"none"}).slideDown(400, function(){
                $(this).css({overflow:"visible", height:"auto", display:"block"});
                });
            },
        function(){
            $sublist.stop().slideUp(400, function(){
            $(this).css({overflow:"hidden", display:"none"});
            });
        });
    });
}