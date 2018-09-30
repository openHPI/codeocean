CodeOceanEditorTurtle = {
  turtlecanvas: null,
  turtlescreen: null,
  resetTurtle: true,

  initTurtle: function () {
    if (this.resetTurtle) {
      this.resetTurtle = false;
      this.turtlecanvas = $('#turtlecanvas');
      this.turtlescreen = new Turtle(this.websocket, this.turtlecanvas);
    }
  },

  cleanUpTurtle: function() {
    this.resetTurtle = true;
  },

  handleTurtleCommand: function (msg) {
    this.initTurtle();
    this.showCanvas();
    if (msg.action in this.turtlescreen) {
      var result = this.turtlescreen[msg.action].apply(this.turtlescreen, msg.args);
      this.websocket.send(JSON.stringify({cmd: 'result', 'result': result}));
    } else {
      this.websocket.send(JSON.stringify({cmd: 'exception', exception: 'AttributeError', message: msg.action}));
    }
    this.websocket.flush();
  },

  handleTurtlebatchCommand: function (msg) {
    this.initTurtle();
    this.showCanvas();
    for (var i = 0; i < msg.batch.length; i++) {
      var cmd = msg.batch[i];
      this.turtlescreen[cmd[0]].apply(this.turtlescreen, cmd[1]);
    }
  },

  showCanvas: function () {
    if ($('#turtlediv').isPresent()
        && this.turtlecanvas.hasClass('hidden')) {
      // initialize two-column layout
      $('#output-col1').addClass('col-lg-7 col-md-7 two-column');
      this.turtlecanvas.removeClass('hidden');
    }
  }

};