var currentTool = null;
var there_is_change_without_save = false;

function canvasSupport() {
  return !!document.createElement('canvas').getContext;
}

function windowCloseHanlder(event) {
  if( there_is_change_without_save ) {
    var event = event || window.event;

    //IE & Firefox
    if (event) {
      event.returnValue = 'Are you sure?';
    }

    // For Safari
    return 'Are you sure?';
  }
}

function submenuToggle(){
  var left = $("#tools").find("a").offset().left;
  $("#tools").find(".submenu").css('left', left);
  $("#tools").find(".submenu").slideToggle(150);
}

function toolChanger(event, element) {
  if (element.id == 'hand-tool') {
    currentTool = 'hand';
  }

  if (element.id == 'text-tool') {
    currentTool = 'text';
  }

  if (element.id == 'brush-tool') {
    currentTool = 'brush';
  }

  $("#tools").find(".submenu").slideUp(150);
  $("#box-tools").hide(150);
}

function getToolSelected() {
  return currentTool;
}

function renderImage(url, editions_by_user) {
  var container = document.querySelector("main");

  var div = document.createElement("div"); // Create div where the page will be rendered
  div.setAttribute("id", "page-1"); // Set id attribute with page-pdf_page_number format
  div.setAttribute("style", "position: relative"); // This will keep positions of child elements as per our needs
  container.appendChild(div); // Append div within main#container

  var canvas = document.createElement("canvas"); // Create a new Canvas element
  canvas.setAttribute('id', "canvas-1"); // Set ID for the Canvas element
  div.appendChild(canvas); // Append Canvas within div#page-pdf_page_number

  var img = new Image();
  img.src = editions_by_user != null ? editions_by_user["canvas-1"] : url;

  img.onload = function () {
    canvas.height = img.height;
    canvas.width = img.width;
    canvas.getContext('2d').drawImage(img, 0, 0);
  };

  $("canvas").mouseover(function(event){
    var canvasID = "#" + $(this).attr('id');

    var canvas = document.querySelector(canvasID);
    var context = canvas.getContext('2d');

    write(canvas, context);
  });
}

function renderPDF(url, editions_by_user) {
  PDFJS.getDocument(url).then(function(pdf){
    // Get main#container and cache it for later use
    var container = document.querySelector("main");

    // Loop from 1 to total_number_of_pages in PDF document
    for (var i = 1; i <= pdf.numPages; i++) {
      // Get desired page
      pdf.getPage(i).then(function(page) {
        var scale = 1.5; // Set scale (zoom) level
        var viewport = page.getViewport(scale); // Get viewport (dimensions)

        var div = document.createElement("div"); // Create div where the page will be rendered
        div.setAttribute("id", "page-" + (page.pageIndex + 1)); // Set id attribute with page-pdf_page_number format
        div.setAttribute("style", "position: relative"); // This will keep positions of child elements as per our needs
        container.appendChild(div); // Append div within main#container

        var canvas = document.createElement("canvas"); // Create a new Canvas element
        canvas.setAttribute('id', "canvas-" + (page.pageIndex + 1)); // Set ID for the Canvas element
        div.appendChild(canvas); // Append Canvas within div#page-pdf_page_number

        var context = canvas.getContext('2d'); // Fetch canvas 2d context
        canvas.height = viewport.height; // Set height dimension to Canvas
        canvas.width = viewport.width; // Set width dimension to Canvas

        // Prepare object needed by render method
        var renderContext = {
          canvasContext: context,
          viewport: viewport
        };

        // Render PDF page
        page.render(renderContext)
          .then(function(){
            if(editions_by_user != null){
              $("main").find("canvas").each(function(index, canvas){
                var img = new Image();
                img.src = editions_by_user[canvas.id];

                img.onload = function () {
                  canvas.getContext('2d').drawImage(img, 0, 0);
                };
              });
            }

            $("canvas").mouseover(function(event){
              var canvasID = "#" + $(this).attr('id');

              var canvas = document.querySelector(canvasID);
              var context = canvas.getContext('2d');

              write(canvas, context);
            });
          });
      });
    }
  });
}

function write(canvas, context) {
  var clickX = [];
  var clickY = [];
  var clickDrag = [];
  var currentTool = getToolSelected();
  var dragging_through_paper = false;

  switch (currentTool) {
    case 'hand':
      canvas.style.cursor = 'grab';
      break;
    case 'text':
      canvas.style.cursor = 'text';
      break;
    case 'brush':
      canvas.style.cursor = 'crosshair';
      break;
    default:
      canvas.style.cursor = 'default';
  }

  canvas.onmousedown = function(event){
    var mouseX = event.pageX - $(this).offset().left;
    var mouseY = event.pageY - $(this).offset().top;

    var keynum = event.which || event.keyCode;

    if (keynum == 1) { // Left mouse button is pressed

      addClick(mouseX, mouseY);

      if (getToolSelected() == 'hand') {
        dragging_through_paper = true;
        drawScreen(context, clickX, clickY, clickDrag, currentTool);
      }

      if (getToolSelected() == 'text') {
        var box_text = $("<div class='box'>").css({"position": "absolute", "top": mouseY, "left": mouseX});
        var close_button = $("<div onclick='insertText(event, this)'>").addClass("close-button");
        var close_text = $("<span>").addClass("close").addClass("close-box-text").html("&times;");
        var input_textarea = $("<textarea class='box-text'>").css({'height':'100px', 'width':'250px'});

        $(close_button).append(close_text);
        $(box_text).append(close_button);
        $(box_text).append(input_textarea);

        $(canvas).closest('div').append(box_text);
      }

      if (getToolSelected() == 'brush') {
        dragging_through_paper = true;
        there_is_change_without_save = true;
        drawScreen(context, clickX, clickY, clickDrag, currentTool);
      }
    }

    if (keynum == 3) { // Right mouse button is pressed
      var toolsBox = document.querySelector("#box-tools");
      $(toolsBox).css({"top": mouseY + $(canvas).offset().top, "left": mouseX + $(canvas).offset().left}).show();
      dragElement(toolsBox);
    }
  };

  canvas.onmousemove = function(event){
    if(dragging_through_paper && getToolSelected() == 'brush'){
      let mouseX = event.pageX - $(this).offset().left;
      let mouseY = event.pageY - $(this).offset().top;

      addClick(mouseX, mouseY, true);
      there_is_change_without_save = true;
      drawScreen(context, clickX, clickY, clickDrag, currentTool);
    }

    if(dragging_through_paper && getToolSelected() == 'hand'){
      canvas.style.cursor = 'grabbing';
      let mouseX = event.pageX - $(this).offset().left;
      let mouseY = event.pageY - $(this).offset().top;

      addClick(mouseX, mouseY, true);
      drawScreen(context, clickX, clickY, clickDrag, currentTool);
    }
  };

  canvas.onmouseup = function(event){
    dragging_through_paper = false;
    if (getToolSelected() == 'hand') {
      canvas.style.cursor = 'grab';
    }
  };

  function addClick(x, y, dragging){
    clickX.push(x);
    clickY.push(y);
    clickDrag.push(dragging);
  }
}

function drawScreen(context, clickX, clickY, clickDrag, currentTool, message){
  switch (currentTool) {
    case 'hand':
      canvasHand(context, clickX, clickY, clickDrag);
      break;
    case 'text':
      canvasText(context, clickX, clickY, message);
      break;
    case 'brush':
      canvasBrush(context, clickX, clickY, clickDrag);
      break;
    // default:
  }
}

function insertText(event, element) {
  var message = $(element).siblings("textarea").val();
  var canvas = $(element).closest(".box").siblings("canvas")[0];
  var context = canvas.getContext('2d');
  var positionX = event.pageX - $(canvas).offset().left - $(element).position().left;
  var positionY = event.pageY - $(canvas).offset().top - $(element).position().top;
  var tool = getToolSelected();

  drawScreen(context, positionX, positionY, false, tool, message);

  $(element).closest('.box').remove();
}

function closeDiv(event, element) {
  $(element).closest('.box').remove();
}

function hideDiv(event, element) {
  $(element).closest('div').hide();
}

function canvasBrush(context, clickX, clickY, clickDrag) {
  context.save();
  context.strokeStyle = "#000000";
  context.lineJoin = "round";
  context.lineWidth = 2;

  for(var i=0; i < clickX.length; i++) {
    context.beginPath();

    if(clickDrag[i] && i){
      context.moveTo(clickX[i-1], clickY[i-1]);
    }else{
      context.moveTo(clickX[i]-1, clickY[i]);
    }

    context.lineTo(clickX[i], clickY[i]);
    context.closePath();
    context.stroke();
  }

  context.restore();
}

function canvasHand(context, clickX, clickY, clickDrag) {
  var canvas = context.canvas;

  for(var i=0; i < clickX.length; i++) {

    if(clickDrag[i] && i){
      $(window).scrollTop($(window).scrollTop() + (clickY[i-1] - clickY[i]));
    }
  }
}

function canvasText(context, clickX, clickY, message) {
  if (message != "") {
    there_is_change_without_save = true;
  }

  context.save();
  context.font = "14px sans-serif";
  context.fillStyle = "#000000";

  var metrics = context.measureText(message);
  var textWidth = metrics.width;

  var xPosition = clickX;
  var yPosition = clickY;

  context.fillText(message, xPosition, yPosition);
  context.restore();
}

function canvasArrow(context, fromX, fromY, toX, toY){
  context.save();

  var headLength = 10;
  var angle = Math.atan2(toY-fromY,toX-fromX);

  context.strokeStyle = "#000000";
  context.lineJoin = "round";
  context.lineWidth = 2;

  context.beginPath();

  // Create line
  context.moveTo(fromX, fromY);
  context.lineTo(toX, toY);

  // Create arrow head
  context.lineTo(toX-headLength*Math.cos(angle-Math.PI/6),toY-headLength*Math.sin(angle-Math.PI/6));
  context.moveTo(toX, toY);
  context.lineTo(toX-headLength*Math.cos(angle+Math.PI/6),toY-headLength*Math.sin(angle+Math.PI/6));

  context.closePath();
  context.stroke();
  context.restore();
}

function salving(){
  $.fancybox.open($('#loading'));
}

function flash_message(msg, css_class, div_to_show, onclick_function, object) {
  var div_to_show = (typeof div_to_show == "undefined" || div_to_show == '') ? $(".flash_message_wrapper:last") : $("." + div_to_show);
  if(!div_to_show.length)
    div_to_show = $(".flash_message_wrapper:last")

  if(typeof div_to_show == "undefined"){
    div_to_show = $(".flash_message_wrapper");
    if(!div_to_show.parents('.undefined-sticky-wrapper').length())
      div_to_show.height($("#flash_message").height() + 20);
  }

  erase_flash_messages();

  if(typeof msg != 'undefined'){
    if (typeof onclick_function != "undefined")
      var onclick_function = onclick_function + "()";

    var html = '<div id="flash_message" class="' + css_class + '" onclick='+onclick_function+'><span id="flash_message_span">' + msg + '</span><span class="close"><a onclick="javascript:erase_flash_messages(true);" onkeydown="javascript:click_on_keypress(event, this);" href="#void"><i class="icon-cross" aria-hidden="true"></i></a></span></div>';
    div_to_show.prepend($(html));

    $("#flash_message").closest(".sticky-wrapper").css("height","40px").css("width", "auto");
  }
}

function erase_flash_messages(focus, obj) {
  if(focus == undefined)
    focus = false;

  if ($('#flash_message')) {
    $('#flash_message').closest(".sticky-wrapper").css("height","0");
    $(".flash_message_wrapper").children().remove();
    $("#flash_message").remove();

    return true;
  }
}

function dragElement(element) {
  var pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
  if (document.getElementById(element.id + "-header")) {
    /* if present, the header is where you move the DIV from:*/
    document.getElementById(element.id + "-header").onmousedown = dragMouseDown;
  } else {
    /* otherwise, move the DIV from anywhere inside the DIV:*/
    element.onmousedown = dragMouseDown;
  }

  function dragMouseDown(event) {
    event = event || window.event;
    event.preventDefault();

    // get the mouse cursor position at startup:
    pos3 = event.clientX;
    pos4 = event.clientY;
    document.onmouseup = closeDragElement;

    // call a function whenever the cursor moves:
    document.onmousemove = elementDrag;
  }

  function elementDrag(event) {
    event = event || window.event;
    event.preventDefault();

    // calculate the new cursor position:
    pos1 = pos3 - event.clientX;
    pos2 = pos4 - event.clientY;
    pos3 = event.clientX;
    pos4 = event.clientY;

    // set the element's new position:
    element.style.top = (element.offsetTop - pos2) + "px";
    element.style.left = (element.offsetLeft - pos1) + "px";
  }

  function closeDragElement() {
    /* stop moving when mouse button is released:*/
    document.onmouseup = null;
    document.onmousemove = null;
  }
}
