function canvasSupport() {
  return !!document.createElement('canvas').getContext;
}

function randomize (array) {
  return  Math.floor(Math.random() * array.length);
}

function redraw(context, clickX, clickY, clickDrag, currentTool){
  // context.clearRect(0, 0, context.canvas.width, context.canvas.height); // Clears the canvas

  if (currentTool == 'brush') {
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
}
