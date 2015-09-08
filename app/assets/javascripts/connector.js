/*$(function() {
    var websocket,
        turtlescreen,
        numMessages = 0,
        turtlecanvas = $('#turtlecanvas'),
        prompt = $('#prompt'),
        commands = ['input', 'write', 'turtle', 'turtlebatch'],
        streams = ['stdin', 'stdout', 'stderr'];

    var ENTER_KEY_CODE = 13;

    var init = function(host) {
        initWebsocket(host);
        initTurtle();
    };

    var initWebsocket = function(host) {
        // todo use host param
        var wsUri = 'ws://' + window.location.hostname + ':3333/socket/510c8a4225ec';
        //var wsUri = "ws://127.0.0.1:3333/chat"
        websocket = new WebSocket(wsUri);
        websocket.onopen = function(evt) { onWebSocketOpen(evt) };
        websocket.onclose = function(evt) { onWebSocketClose(evt) };
        websocket.onmessage = function(evt) { onWebSocketMessage(evt) };
        websocket.onerror = function(evt) { onWebSocketError(evt) };
        websocket.flush = function() { this.send('\n'); }
    };

    var initTurtle = function() {
        turtlescreen = new Turtle(websocket, $('#turtlecanvas'));
    };

    var initCallbacks = function() {
        if ($('#run').isPresent()) {
            $('#run').bind('click', function(event) {
                // todo parse host from data property
                // var host = $(".docker-terminal").data('docker-host');
                init(null);
                hideCanvas();
                hidePrompt();
            });
        }
        if ($('#prompt').isPresent()) {
            $('#prompt').on('keypress', handlePromptKeyPress);
            $('#prompt-submit').on('click', submitPromptInput);
        }
    }

    var onWebSocketOpen = function(evt) {
        //alert("Session started");
    };

    var onWebSocketClose = function(evt) {
        //alert("Session terminated");
    };

    var onWebSocketMessage = function(evt) {
        numMessages++;
        parseCanvasMessage(evt.data, true);
    };

    var onWebSocketError = function(evt) {
        //alert("Something went wrong.")
    };

    var executeCommand = function(msg) {
        if ($.inArray(msg.cmd, commands) == -1) {
            console.log("Unknown command: " + msg.cmd);
            // skipping unregistered commands is required
            // as we may receive mirrored response due to internal behaviour
            return;
        }
        switch(msg.cmd) {
            case 'input':
                showPrompt();
                break;
            case 'write':
                printOutput(msg);
                break;
            case 'turtle':
                showCanvas();
                handleTurtleCommand(msg);
                break;
            case 'turtlebatch':
                showCanvas();
                handleTurtlebatchCommand(msg);
                break;
        }
    };

    // todo reuse method from editor.js
    var printOutput = function(msg) {
        var element = findOrCreateOutputElement(0);
        console.log(element);
        switch (msg.stream) {
            case 'internal':
                element.addClass('text-danger');
                break;
            case 'stderr':
                element.addClass('text-warning');
                break;
            case 'stdout':
            case 'stdin': // for eventual prompts
            default:
                element.addClass('text-muted');
        }
        element.append(msg.data)
    };

    // taken from editor.js
    var findOrCreateOutputElement = function(index) {
        if ($('#output-' + index).isPresent()) {
          return $('#output-' + index);
        } else {
          var element = $('<pre>').attr('id', 'output-' + index);
          $('#output').append(element);
          return element;
        }
    };

    var handleTurtleCommand = function(msg) {
        if (msg.action in turtlescreen) {
            result = turtlescreen[msg.action].apply(turtlescreen, msg.args);
            websocket.send(JSON.stringify({cmd: 'result', 'result': result}));
        } else {
            websocket.send(JSON.stringify({cmd: 'exception', exception: 'AttributeError', message: msg.action}));
        }
        websocket.flush();
    };

    var handleTurtlebatchCommand = function(msg) {
        for (i = 0; i < msg.batch.length; i++) {
            cmd = msg.batch[i];
            turtlescreen[cmd[0]].apply(turtlescreen, cmd[1]);
        }
    };

    var handlePromptKeyPress = function(evt) {
        if (evt.which === ENTER_KEY_CODE) {
            submitPromptInput();
        }
    }

    var submitPromptInput = function() {
        var input = $('#prompt-input');
        var message = input.val();
        websocket.send(JSON.stringify({cmd: 'result', 'data': message}));
        websocket.flush();
        input.val('');
        hidePrompt();
    }

    var parseCanvasMessage = function(message, recursive) {
        var msg;
        message = message.replace(/^\s+|\s+$/g, "");
        try {
            // todo validate json instead of catching
            msg = JSON.parse(message);
        } catch (e) {
            if (!recursive) {
                return false;
            }
            // why does docker sometimes send multiple commands at once?
            message = message.replace(/^\s+|\s+$/g, "");
            messages = message.split("\n");
            for (var i = 0; i < messages.length; i++) {
                if (!messages[i]) {
                    continue;
                }
                parseCanvasMessage(messages[i], false);
            }
            return;
        }
        executeCommand(msg);
    };

    var showPrompt = function() {
        if (prompt.isPresent() && prompt.hasClass('hidden')) {
            prompt.removeClass('hidden');
        }
        prompt.focus();
    }

    var hidePrompt = function() {
        if (prompt.isPresent() && !prompt.hasClass('hidden')) {
            console.log("hiding prompt2");
            prompt.addClass('hidden');
        }
    }

    var showCanvas = function() {
        if ($('#turtlediv').isPresent()
                && turtlecanvas.hasClass('hidden')) {
            // initialize two-column layout
            $('#output-col1').addClass('col-lg-7 col-md-7 two-column');
            turtlecanvas.removeClass('hidden');
        }
    };

    var hideCanvas = function() {
        if ($('#turtlediv').isPresent()
                && !(turtlecanvas.hasClass('hidden'))) {
            output = $('#output-col1');
            if (output.hasClass('two-column')) {
                output.removeClass('col-lg-7 col-md-7 two-column');
            }
            turtlecanvas.addClass('hidden');
        }
    };

    initCallbacks();
});
*/
