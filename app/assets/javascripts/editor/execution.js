CodeOceanEditorWebsocket = {
  websocket: null,

  createSocketUrl: function(url) {
      const sockURL = new URL(url, window.location);
      // not needed any longer, we put it directly into the url: sockURL.pathname = url;

      // replace `http` with `ws` for the WebSocket connection. This also works with `https` and `wss`.
      sockURL.protocol = sockURL.protocol.replace("http", "ws");

      // strip anchor if it is in the url
      sockURL.hash = '';

      return sockURL.toString();
  },

  initializeSocket: function(url) {
    this.websocket = new CommandSocket(this.createSocketUrl(url),
        function (evt) {
          this.resetOutputTab();
        }.bind(this)
    );
    CodeOceanEditorWebsocket.websocket = this.websocket;
    this.websocket.onError(this.showWebsocketError.bind(this));
  },

  initializeSocketForTesting: function(url) {
    this.initializeSocket(url);
    this.websocket.on('default',this.handleTestResponse.bind(this));
    this.websocket.on('exit', this.handleExitCommand.bind(this));
  },

  initializeSocketForScoring: function(url) {
    this.initializeSocket(url);
    this.websocket.on('default',this.handleScoringResponse.bind(this));
    this.websocket.on('hint', this.showHint.bind(this));
    this.websocket.on('exit', this.handleExitCommand.bind(this));
  },

  initializeSocketForRunning: function(url) {
    this.initializeSocket(url);
    this.websocket.on('input',this.showPrompt.bind(this));
    this.websocket.on('write', this.printWebsocketOutput.bind(this));
    this.websocket.on('clear', this.clearOutput.bind(this));
    this.websocket.on('turtle', this.handleTurtleCommand.bind(this));
    this.websocket.on('turtlebatch', this.handleTurtlebatchCommand.bind(this));
    this.websocket.on('render', this.printWebsocketOutput.bind(this));
    this.websocket.on('exit', this.handleExitCommand.bind(this));
    this.websocket.on('status', this.showStatus.bind(this));
    this.websocket.on('hint', this.showHint.bind(this));
    this.websocket.on('files', this.prepareFileDownloads.bind(this));
  },

  handleExitCommand: function() {
    this.killWebsocket();
    this.handleQaApiOutput();
    this.handleStderrOutputForFlowr();
    this.augmentStacktraceInOutput();
    this.cleanUpTurtle();
    this.cleanUpUI();
  }
};
