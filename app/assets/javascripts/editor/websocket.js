CommandSocket = function(url, onOpen) {
  this.handlers = {};
  this.websocket = new WebSocket(url);
  this.websocket.onopen = onOpen;
  this.websocket.onmessage = this.onMessage.bind(this);
  this.websocket.flush = function () {
    if (this.readyState === this.OPEN) {
        this.send('\n');
    }
  }
};

CommandSocket.prototype.onError = function(callback){
  this.websocket.onerror = callback
};

/**
 * Allows it to register an event-handler on the given cmd.
 * The handler needs to accept one argument, the message.
 * There is only handler per command at the moment.
 * @param command
 * @param handler
 */
CommandSocket.prototype.on = function(command, handler) {
  this.handlers[command] = handler;
};


/**
 * Used to initialize the recursive message parser.
 * @param event
 */
CommandSocket.prototype.onMessage = function(event) {
  //Parses the message (serches for linebreaks) and executes every contained cmd.
  this.parseMessage(event.data, true)
};

/**
 * Parses a message, checks whether it contains multiple commands (seperated by linebreaks)
 * This needs to be done because of the behavior of the docker-socket connection.
 * Because of this, sometimes multiple commands might be executed in one message.
 * @param message
 * @param recursive
 * @returns {boolean}
 */
CommandSocket.prototype.parseMessage = function(message, recursive) {
  var msg;
  var message_string = message.replace(/^\s+|\s+$/g, "");
  try {
    // todo validate json instead of catching
    msg = JSON.parse(message_string);
  } catch (e) {
    if (!recursive) {
      return false;
    }
    // why does docker sometimes send multiple commands at once?
    message_string = message_string.replace(/^\s+|\s+$/g, "");
    var messages = message_string.split("\n");
    for (var i = 0; i < messages.length; i++) {
      if (!messages[i]) {
        continue;
      }
      this.parseMessage(messages[i], false);
    }
    return;
  }
  this.executeCommand(msg);
};

/**
 * Executes the handler that is registered for a certain command.
 * Does nothing if the command was not specified yet.
 * If there is a null-handler (defined with on('default',func)) this gets
 * executed if the command was not registered or the message has no cmd prop.
 * @param cmd
 */
CommandSocket.prototype.executeCommand = function(cmd) {
  if ('cmd' in cmd && cmd.cmd in this.handlers) {
    this.handlers[cmd.cmd](cmd);
  } else if ('default' in this.handlers) {
    this.handlers['default'](cmd);
  }
};

/**
 * Used to send a message through the socket.
 * If data is not a string we'll try use jsonify to make it a string.
 * @param data
 */
CommandSocket.prototype.send = function(data) {
  // Only send message if WebSocket is open and ready.
  // Ignore all other messages (they might hit a wrong container anyway)
  if (this.getReadyState() === this.websocket.OPEN) {
    this.websocket.send(data);
  }
};

/**
 * Returns the ready state of the socket.
 */
CommandSocket.prototype.getReadyState = function() {
  return this.websocket.readyState;
};

/**
 * Flush the websocket.
 */
CommandSocket.prototype.flush = function() {
  this.websocket.flush();
};

/**
 * Closes the websocket.
 */
CommandSocket.prototype.killWebSocket = function() {
  this.websocket.flush();
  this.websocket.close(1000);
};
