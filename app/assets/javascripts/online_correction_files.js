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
    // TODO: code here
  }
}

function paint(canvas, context) {
  var clickX = [];
  var clickY = [];
  var clickDrag = [];
  var currentTool = 'brush';
  var paint = false;

  canvas.onmousedown = function(event){
    var mouseX = event.pageX - $(this).offset().left;
    var mouseY = event.pageY - $(this).offset().top;

    paint = true;
    addClick(mouseX, mouseY);
    redraw(context, clickX, clickY, clickDrag, currentTool);
  };

  canvas.onmousemove = function(event){
    if(paint){
      var mouseX = event.pageX - $(this).offset().left;
      var mouseY = event.pageY - $(this).offset().top;

      addClick(mouseX, mouseY, true);
      redraw(context, clickX, clickY, clickDrag, currentTool);
    }
  };

  canvas.onmouseup = function(event){
    paint = false;
  };

  function addClick(x, y, dragging){
    clickX.push(x);
    clickY.push(y);
    clickDrag.push(dragging);
  }
}

function redraw(context, clickX, clickY, clickDrag, currentTool){
  context.save();

  if (currentTool == 'brush') {
    context.strokeStyle = "#000000";
    context.lineJoin = "round";
    context.lineWidth = 2;
  }

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
