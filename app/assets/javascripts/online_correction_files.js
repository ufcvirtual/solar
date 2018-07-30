var currentTool = null;

function canvasSupport() {
  return !!document.createElement('canvas').getContext;
}

function submenuToggle(event, element){
  var left = $("#tools").find("a").offset().left;
  $("#tools").find(".submenu").css('left', left);
  $("#tools").find(".submenu").slideToggle(150);
}

function toolChanger(event, element) {
  if (element.id == 'brush-tool') {
    currentTool = 'brush';
  }

  if (element.id == 'text-tool') {
    currentTool = 'text';
  }

  $("#tools").find(".submenu").slideUp(150);
}

function getToolSelected() {
  return currentTool;
}

function write(canvas, context) {
  var clickX = [];
  var clickY = [];
  var clickDrag = [];
  var currentTool = getToolSelected();
  var pen_touching_paper = false;

  switch (currentTool) {
    case 'brush':
      canvas.style.cursor = 'crosshair';
      break;
    case 'text':
      canvas.style.cursor = 'text';
      break;
    default:
      canvas.style.cursor = 'default';
  }

  canvas.onmousedown = function(event){
    var keynum = event.which || event.keyCode;

    if (keynum == 1) { // Left mouse button is pressed
      var mouseX = event.pageX - $(this).offset().left;
      var mouseY = event.pageY - $(this).offset().top;

      addClick(mouseX, mouseY);

      if (getToolSelected() == 'brush') {
        pen_touching_paper = true;
        drawScreen(context, clickX, clickY, clickDrag, currentTool);
      }

      if (getToolSelected() == 'text') {
        var box_text = $("<div>").css({"position": "absolute", "top": mouseY, "left": mouseX});
        var close_button = $("<span onclick='closeDiv(event, this)'>").addClass("close").html("&times;");
        var input_textarea = $("<textarea>").css({'height':'100px', 'width':'250px'});

        $(box_text).append(close_button);
        $(box_text).append(input_textarea);

        $(canvas).closest('div').append(box_text);
      }
    }

    if (keynum == 3) { // Right mouse button is pressed
      // TODO: abrir caixa de ferramentas
    }
  };

  canvas.onmousemove = function(event){
    if(pen_touching_paper && getToolSelected() == 'brush'){
      var mouseX = event.pageX - $(this).offset().left;
      var mouseY = event.pageY - $(this).offset().top;

      addClick(mouseX, mouseY, true);
      drawScreen(context, clickX, clickY, clickDrag, currentTool);
    }
  };

  canvas.onmouseup = function(event){
    pen_touching_paper = false;
  };

  function addClick(x, y, dragging){
    clickX.push(x);
    clickY.push(y);
    clickDrag.push(dragging);
  }
}

function drawScreen(context, clickX, clickY, clickDrag, currentTool, message){
  context.save();

  if (currentTool == 'brush') {
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
  }

  if (currentTool == 'text') {
    context.font = "14px sans-serif";
    context.fillStyle = "#000000";

    var metrics = context.measureText(message);
    var textWidth = metrics.width;

    var xPosition = clickX;
    var yPosition = clickY;

    context.fillText(message, xPosition, yPosition);
  }

  context.restore();
}

function closeDiv(event, element) {
  var message = $(element).siblings("textarea").val();
  var canvas = $(element).closest("div").siblings("canvas")[0];
  var context = canvas.getContext('2d');
  var positionX = event.pageX - $(canvas).offset().left - $(element).position().left;
  var positionY = event.pageY - $(canvas).offset().top - $(element).position().top;
  var tool = getToolSelected();

  drawScreen(context, positionX, positionY, false, tool, message);

  $(element).closest('div').remove();
}
