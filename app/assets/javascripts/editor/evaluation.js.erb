CodeOceanEditorEvaluation = {
  chunkBuffer: [{streamedResponse: true}],

  /**
   * Scoring-Functions
   */
  scoreCode: function (event) {
    event.preventDefault();
    this.clearScoringOutput();
    this.createSubmission('#assess', null, function (response) {
      this.showSpinner($('#assess'));
      $('#score_div').removeClass('hidden');
      var url = response.score_url;
      this.initializeSocketForScoring(url);
    }.bind(this));
  },

  handleScoringResponse: function (results) {
    this.printScoringResults(results);
    var score = _.reduce(results, function (sum, result) {
      return sum + result.score * result.weight;
    }, 0).toFixed(2);
    $('#score').data('score', score);
    this.renderScore();
  },

  printScoringResult: function (result, index) {
    $('#results').show();
    var panel = $('#dummies').children().first().clone();
    this.populatePanel(panel, result, index);
    $('#results ul').first().append(panel);
  },

  printScoringResults: function (response) {
    $('#results ul').first().html('');
    $('.test-count .number').html(response.length);
    this.clearOutput();

    _.each(response, function (result, index) {
      this.printOutput(result, false, index);
      this.printScoringResult(result, index);
    }.bind(this));

    if (_.some(response, function (result) {
          return result.status === 'timeout';
        })) {
      this.showTimeoutMessage();
    }
    if (_.some(response, function (result) {
          return result.status === 'container_depleted';
        })) {
      this.showContainerDepletedMessage();
    }
    if (this.qa_api) {
      // send test response to QA
      this.qa_api.executeCommand('syncOutput', [response]);
    }
  },

  renderHint: function (object) {
    var hint = object.data || object.hint;
    if (hint) {
      $('#hint .panel-body').text(hint);
      $('#hint').fadeIn();
    }
  },

  renderScore: function () {
    var score = parseFloat($('#score').data('score'));
    var maximum_score = parseFloat($('#score').data('maximum-score'));
    if (score >= 0 && score <= maximum_score && maximum_score > 0) {
      var percentage_score = (score / maximum_score * 100 ).toFixed(0);
      $('.score').html(percentage_score + '%');
    }
    else {
      $('.score').html(0 + '%');
    }
    this.renderProgressBar(score, maximum_score);
  },

  /**
   * Testing-Logic
   */
  handleTestResponse: function (result) {
    this.clearOutput();
    this.printOutput(result, false, 0);
    if (this.qa_api) {
      this.qa_api.executeCommand('syncOutput', [result]);
    }
    this.showStatus(result);
    this.showOutputBar();
  },

  /**
   * Stop-Logic
   */
  stopCode: function (event) {
    event.preventDefault();
    if (this.isActiveFileStoppable()) {
      this.websocket.send(JSON.stringify({'cmd': 'client_kill'}));
      this.killWebsocket();
      this.cleanUpUI();
    }
  },

  killWebsocket: function () {
    if (this.websocket != null && this.websocket.getReadyState() != WebSocket.OPEN) {
      return;
    }

    this.websocket.killWebSocket();
    this.running = false;
  },

  cleanUpUI: function() {
    this.hideSpinner();
    this.toggleButtonStates();
    this.hidePrompt();
  },

  /**
   * Output-Logic
   */
  renderWebsocketOutput: function(msg){
    var element = this.findOrCreateRenderElement(0);
    element.append(msg.data);
  },

  printWebsocketOutput: function(msg) {
    if (!msg.data) {
      return;
    }
    msg.data = msg.data.replace(/(\r)/gm, "\n");
    var stream = {};
    stream[msg.stream] = msg.data;
    this.printOutput(stream, true, 0);
  },

  clearOutput: function() {
    $('#output pre').remove();
  },

  clearScoringOutput: function() {
    $('#results ul').first().html('');
    $('.test-count .number').html(0);
    $('#score').data('score', 0);
    this.renderScore();
    this.clearOutput();
  },

  printOutput: function (output, colorize, index) {
    var element = this.findOrCreateOutputElement(index);
    if (!colorize) {
      if (output.stdout != undefined && output.stdout != '') {
        element.append(output.stdout)
        //element.text(element.text() + output.stdout)
      }

      if (output.stderr != undefined && output.stderr != '') {
          element.append('StdErr: ' + output.stderr);
        //element.text('StdErr: ' + element.text() + output.stderr);
      }

    } else if (output.stderr) {
        element.addClass('text-warning').append(output.stderr);
        //element.addClass('text-warning').text(element.text() + output.stderr);
      this.flowrOutputBuffer += output.stderr;
      this.QaApiOutputBuffer.stderr += output.stderr;
    } else if (output.stdout) {
        element.addClass('text-success').append(output.stdout);
        //element.addClass('text-success').text(element.text() + output.stdout);
      this.flowrOutputBuffer += output.stdout;
      this.QaApiOutputBuffer.stdout += output.stdout;
    } else {
      element.addClass('text-muted').text($('#output').data('message-no-output'));
    }
  }


};
