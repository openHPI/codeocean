CodeOceanEditorWebsocket = {
  websocket: null,
  // Replace `http` with `ws` for the WebSocket connection. This also works with `https` and `wss`.
  webSocketProtocol: window.location.protocol.replace(/^http/, 'ws').split(':')[0],

  initializeSocket: function(urlHelper, params, closeCallback) {
    // 1. Specify the protocol for all URLs to generate
    params.protocol = this.webSocketProtocol;
    params._options = true;

    // 2. Create a new Sentry transaction.
    //    Since we want to group similar URLs, we use the URL without the ID and filename as the description.
    const cleanedUrl = urlHelper({
      ...params,
      ...(params.id && {id: '*'}), // Overwrite the ID with a wildcard only if it is present.
      ...(params.filename && {filename: '*'}), // Overwrite the filename with a wildcard only if it is present.
    });
    const sentryDescription = `WebSocket ${cleanedUrl}`;
    const span = this.sentryTransaction?.startChild({op: 'websocket.client', description: sentryDescription, data: {...params}})

    // 3. Create the actual WebSocket URL.
    //    This URL might contain Sentry Tracing headers to propagate the Sentry transaction.
    if (span) {
      const dynamicContext = this.sentryTransaction.getDynamicSamplingContext();
      const baggage = SentryUtils.dynamicSamplingContextToSentryBaggageHeader(dynamicContext);
      if (baggage) {
        params.HTTP_SENTRY_TRACE = span.toTraceparent();
        params.HTTP_BAGGAGE = baggage;
      }
    }
    const url = urlHelper({...params});

    // 4. Connect to the given URL.
    this.websocket = new CommandSocket(url,
        function (evt) {
          this.resetOutputTab();
        }.bind(this)
    );
    CodeOceanEditorWebsocket.websocket = this.websocket;
    this.websocket.onError(this.showWebsocketError.bind(this));
    this.websocket.onClose(function(span, callback){
      span?.finish();
      if(callback != null){
        callback();
      }
    }.bind(this, span, closeCallback));
  },

  initializeSocketForTesting: function(submissionID, filename) {
    this.initializeSocket(Routes.test_submission_url, {id: submissionID, filename: filename});
    this.websocket.on('default',this.handleTestResponse.bind(this));
    this.websocket.on('exit', this.handleExitCommand.bind(this));
  },

  initializeSocketForScoring: function(submissionID) {
    this.initializeSocket(Routes.score_submission_url, {id: submissionID}, function() {
      $('#assess').one('click', this.scoreCode.bind(this))
    }.bind(this));
    this.websocket.on('default',this.handleScoringResponse.bind(this));
    this.websocket.on('hint', this.showHint.bind(this));
    this.websocket.on('exit', this.handleExitCommand.bind(this));
    this.websocket.on('status', this.showStatus.bind(this));
  },

  initializeSocketForRunning: function(submissionID, filename) {
    this.initializeSocket(Routes.run_submission_url, {id: submissionID, filename: filename});
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
    this.handleStderrOutputForFlowr();
    this.augmentStacktraceInOutput();
    this.cleanUpTurtle();
    this.cleanUpUI();
  }
};
