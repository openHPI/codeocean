CodeOceanEditorWebsocket = {
  websocket: null,
  // Replace `http` with `ws` for the WebSocket connection. This also works with `https` and `wss`.
  webSocketProtocol: window.location.protocol.replace(/^http/, 'ws').split(':')[0],

  runSocket: function(urlHelper, params, setupFunction) {
    // 1. Specify the protocol for all URLs to generate
    params.protocol = this.webSocketProtocol;
    params._options = true;

    // 2. Create a new Sentry span.
    //    Since we want to group similar URLs, we use the URL without the ID and filename as the description.
    const cleanedUrl = urlHelper({
      ...params,
      ...(params.id && {id: '*'}), // Overwrite the ID with a wildcard only if it is present.
      ...(params.filename && {filename: '*'}), // Overwrite the filename with a wildcard only if it is present.
    });
    const sentryDescription = `WebSocket ${cleanedUrl}`;
    return Sentry.startSpan({op: 'websocket.client', name: sentryDescription, attributes: {...params}}, async webSocketSpan => {

      // 3. Create the actual WebSocket URL.
      //    This URL might contain Sentry Tracing headers to propagate the Sentry transaction.
      if (webSocketSpan) {
        params.HTTP_SENTRY_TRACE = Sentry.spanToTraceHeader(webSocketSpan);

        const baggage = Sentry.spanToBaggageHeader(webSocketSpan);
        if (baggage) {
          params.HTTP_BAGGAGE = Sentry.spanToBaggageHeader(webSocketSpan);
        }
      }
      const url = urlHelper({...params});

      // 4. Connect to the given URL.
      this.websocket = new CommandSocket(url,
        function (evt) {
          this.resetOutputTab();
        }.bind(this)
      );

      // Attach custom handlers for messages received.
      setupFunction(this.websocket);

      CodeOceanEditorWebsocket.websocket = this.websocket;

      // Create and return a new Promise. It will only resolve (or fail) once the connection has ended.
      return new Promise((resolve, reject) => {
        this.websocket.onError(this.showWebsocketError.bind(this));

        // Remove event listeners for Promise handling.
        // This is especially useful in case of an error, where a `close` event might follow the `error` event.
        const teardown = () => {
          this.websocket.websocket.removeEventListener('close', closeListener);
          this.websocket.websocket.removeEventListener('error', errorListener);
        };

        const closeListener = () => {
          resolve();
          teardown();
        }

        const errorListener = (error) => {
          reject(error);
          teardown();
          this.websocket.killWebSocket(); // In case of error, ensure we always close the connection.
        }

        // We are using event listeners (and not `onError` or `onClose`) here, since these listeners should never be overwritten.
        // With `onError` or `onClose`, a new assignment would overwrite a previous one.
        this.websocket.websocket.addEventListener('close', closeListener);
        this.websocket.websocket.addEventListener('error', errorListener);
      });
    });
  },

  socketTestCode: function(submissionID, filename) {
    return this.runSocket(Routes.test_submission_url, {id: submissionID, filename: filename}, (websocket) => {
      websocket.on('default', this.handleTestResponse.bind(this));
      websocket.on('exit', this.handleExitCommand.bind(this));
    });
  },

  socketScoreCode: function(submissionID) {
    return this.runSocket(Routes.score_submission_url, {id: submissionID}, (websocket) => {
      websocket.on('default', this.handleScoringResponse.bind(this));
      websocket.on('hint', this.showHint.bind(this));
      websocket.on('exit', this.handleExitCommand.bind(this));
      websocket.on('status', this.showStatus.bind(this));
    }).then(() => {
      $('#assess').one('click', this.scoreCode.bind(this));
    });
  },

  socketRunCode: function(submissionID, filename) {
    return this.runSocket(Routes.run_submission_url, {id: submissionID, filename: filename}, (websocket) => {
      websocket.on('input', this.showPrompt.bind(this));
      websocket.on('write', this.printWebsocketOutput.bind(this));
      websocket.on('clear', this.clearOutput.bind(this));
      websocket.on('turtle', this.handleTurtleCommand.bind(this));
      websocket.on('turtlebatch', this.handleTurtlebatchCommand.bind(this));
      websocket.on('render', this.printWebsocketOutput.bind(this));
      websocket.on('exit', this.handleExitCommand.bind(this));
      websocket.on('status', this.showStatus.bind(this));
      websocket.on('hint', this.showHint.bind(this));
      websocket.on('files', this.prepareFileDownloads.bind(this));
    });
  },

  handleExitCommand: function() {
    this.killWebsocket();
    this.handleStderrOutputForFlowr();
    this.augmentStacktraceInOutput();
    this.cleanUpTurtle();
    this.cleanUpUI();
  }
};
