var colors = {
  black: "#000000",
  red: "#FF0000",
  blue: "#0000FF",
};

var currentTool = null;
var currentColor = colors.black;
var there_is_change_without_save = false;
var history_to_undo = [];
var history_for_redo = [];

function canvasSupport() {
  return !!document.createElement('canvas').getContext;
}

function windowCloseHandler(event) {
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

function submenuToggle(event, element){
  var id = $(element).closest("li").attr('id');
  var left = $("#" + id).find("a").offset().left;
  $("#" + id).find(".submenu").css('left', left);
  $("#" + id).find(".submenu").slideToggle(150);
}

function toolChanger(element) {
  var menu_id = $(element).closest(".submenu").closest("li").attr("id");

  if (element.id == 'hand-tool') {
    currentTool = 'hand';
  }

  if (element.id == 'text-tool') {
    currentTool = 'text';
  }

  if (element.id == 'brush-tool') {
    currentTool = 'brush';
  }

  if (element.id == 'undo') {
    undo();
  }

  if (element.id == 'redo') {
    redo();
  }

  if (element.id == 'black') {
    currentColor = colors.black;
  }

  if (element.id == 'red') {
    currentColor = colors.red;
  }

  if (element.id == 'blue') {
    currentColor = colors.blue;
  }

  $("#" + menu_id).find(".submenu").slideUp(150);
}

function getToolSelected() {
  return currentTool;
}

function renderImage(url, editions_by_user) {
  var container = document.querySelector(".container");

  var div = document.createElement("div"); // Create div where the page will be rendered
  div.setAttribute("id", "page-1"); // Set id attribute with page-pdf_page_number format
  div.setAttribute("style", "position: relative"); // This will keep positions of child elements as per our needs
  container.appendChild(div); // Append div within main.container

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

  $("canvas").on("mouseover", function(event){
    var canvasID = "#" + $(this).attr('id');

    var canvas = document.querySelector(canvasID);
    var context = canvas.getContext('2d');

    write(canvas, context);
  });
}

function renderPDF(url, editions_by_user) {
  PDFJS.getDocument(url).then(function(pdf){
    // Get main.container and cache it for later use
    var container = document.querySelector(".container");

    // Loop from 1 to total_number_of_pages in PDF document
    for (var i = 1; i <= pdf.numPages; i++) {
      // Get desired page
      pdf.getPage(i).then(function(page) {
        var scale = 1.5; // Set scale (zoom) level
        var viewport = page.getViewport(scale); // Get viewport (dimensions)

        var div = document.createElement("div"); // Create div where the page will be rendered
        div.setAttribute("id", "page-" + (page.pageIndex + 1)); // Set id attribute with page-pdf_page_number format
        div.setAttribute("style", "position: relative"); // This will keep positions of child elements as per our needs
        container.appendChild(div); // Append div within main.container

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
            $(".container").find("canvas").each(function(index, canvas){
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
        var close_button = $("<div onclick='closeBox(event, this)'>").addClass("close-button");
        var close_text = $("<span>").addClass("close").addClass("close-box-text").html("&times;");
        var input_textarea = $("<textarea class='box-text'>").css({'height':'100px', 'width':'250px'});
        var insert_buuton = $("<button onclick='insertText(event, this)'>").addClass("btn").addClass("btn_main").html(insert_button_name);

        $(close_button).append(close_text);
        $(box_text).append(close_button);
        $(box_text).append(input_textarea);
        $(box_text).append(insert_buuton);

        $(canvas).closest('div').append(box_text);
        saveState(canvas);
      }

      if (getToolSelected() == 'brush') {
        dragging_through_paper = true;
        there_is_change_without_save = true;
        saveState(canvas);
        drawScreen(context, clickX, clickY, clickDrag, currentTool);
      }
    }

    // if (keynum == 3) { // Right mouse button is pressed
    //   var toolsBox = document.querySelector("#box-tools");
    //   $(toolsBox).css({"top": mouseY + $(canvas).offset().top, "left": mouseX + $(canvas).offset().left}).show();
    //   dragElement(toolsBox);
    // }
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
    if (getToolSelected() == 'brush') {
      clickX = [];
      clickY = [];
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

function closeBox(event, element) {
  $(element).closest('.box').remove();
}

function insertText(event, element) {
  var message = $(element).siblings("textarea").val();
  var canvas = $(element).closest(".box").siblings("canvas")[0];
  var context = canvas.getContext('2d');
  var positionX = $(element).offset().left - $(canvas).offset().left - $(element).position().left;
  var positionY = $(element).offset().top - $(canvas).offset().top - $(element).position().top;
  var tool = getToolSelected();

  drawScreen(context, positionX, positionY, false, tool, message);

  $(element).closest('.box').remove();
}

function hideDiv(element) {
  $(element).closest('div').hide();
}

function canvasBrush(context, clickX, clickY, clickDrag) {
  context.save();
  context.strokeStyle = currentColor;
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
  context.fillStyle = currentColor;

  var metrics = context.measureText(message);
  var textWidth = metrics.width;

  var xPosition = clickX;
  var yPosition = clickY;

  printAt(context, message, xPosition+2, yPosition+5, 15, 250);
  context.restore();
}

function printAt(context, text, x, y, lineHeight, fitWidth) {
  fitWidth = fitWidth || 0;

  if (fitWidth <= 0) {
    context.fillText(text, x, y);
    return;
  }

  for (var idx = 1; idx <= text.length; idx++) {
    var str = text.substr(0, idx);
    if (context.measureText(str).width > fitWidth) {
      context.fillText( text.substr(0, idx-1), x, y );
      printAt(context, text.substr(idx-1), x, y + lineHeight, lineHeight,  fitWidth);
      return;
    }
  }
  context.fillText(text, x, y);
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

function saveState(canvas) {
  if (history_to_undo.length >= 10) {
    history_to_undo.shift();
  }
  history_to_undo.push({ canvas_id: canvas.id, img: canvas.toDataURL() });
}

function restoreState(canvas) {
  if (history_for_redo.length >= 10) {
    history_for_redo.shift();
  }
  history_for_redo.push({ canvas_id: canvas.id, img: canvas.toDataURL() });
}

function undo() {
  if(history_to_undo.length) {
    there_is_change_without_save = true;
    var last_canvas = history_to_undo.pop();
    var canvas = document.querySelector("#" + last_canvas.canvas_id);
    restoreState(canvas);

    var img = new Image();
    img.src = last_canvas.img;

    img.onload = function () {
      canvas.getContext('2d').drawImage(img, 0, 0);
    };
  }
}

function redo() {
  if(history_for_redo.length) {
    there_is_change_without_save = true;
    var last_canvas = history_for_redo.pop();
    var canvas = document.querySelector("#" + last_canvas.canvas_id);
    saveState(canvas);

    var img = new Image();
    img.src = last_canvas.img;

    img.onload = function () {
      canvas.getContext('2d').drawImage(img, 0, 0);
    };
  }
}
