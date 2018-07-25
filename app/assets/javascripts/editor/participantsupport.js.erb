CodeOceanEditorFlowr = {
  isFlowrEnabled: true,
  flowrResultHtml: '<div class="panel panel-default"><div id="{{headingId}}" role="tab" class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#flowrHint" href="#{{collapseId}}" aria-expanded="true" aria-controls="{{collapseId}}"></a></h4></div><div id="{{collapseId}}" role="tabpanel" aria-labelledby="{{headingId}}" class="panel-collapse collapse"><div class="panel-body"></div></div></div>',

  handleStderrOutputForFlowr: function () {
    if (!this.isFlowrEnabled) return;

    var flowrUrl = $('#flowrHint').data('url');
    var flowrHintBody = $('#flowrHint .panel-body');
    var queryParameters = {
      query: this.flowrOutputBuffer
    };

    flowrHintBody.empty();

    jQuery.getJSON(flowrUrl, queryParameters, function (data) {
      jQuery.each(data.queryResults, function (index, question) {
        var collapsibleTileHtml = this.flowrResultHtml.replace(/{{collapseId}}/g, 'collapse-' + question).replace(/{{headingId}}/g, 'heading-' + question);
        var resultTile = $(collapsibleTileHtml);

        resultTile.find('h4 > a').text(question.title + ' | Found via ' + question.source);
        resultTile.find('.panel-body').html(question.body);
        resultTile.find('.panel-body').append('<a href="' + question.url + '" class="btn btn-primary btn-block">Open this question</a>');

        flowrHintBody.append(resultTile);
      });

      if (data.queryResults.length !== 0) {
        $('#flowrHint').fadeIn();
      }
    });

    this.flowrOutputBuffer = '';
  }
};

CodeOceanEditorCodePilot = {
  qa_api: undefined,
  QaApiOutputBuffer: {'stdout': '', 'stderr': ''},

  initializeCodePilot: function () {
    if ($('#questions-column').isPresent() && (typeof QaApi != 'undefined') && QaApi.isBrowserSupported()) {
      $('#editor-column').addClass('col-md-10').removeClass('col-md-12');
      $('#questions-column').addClass('col-md-2');

      var node = document.getElementById('questions-holder');
      var url = $('#questions-holder').data('url');

      this.qa_api = new QaApi(node, url);
    }
  },

  handleQaApiOutput: function () {
    if (this.qa_api) {
      this.qa_api.executeCommand('syncOutput', [[this.QaApiOutputBuffer]]);
      // reset the object
    }
    this.QaApiOutputBuffer = {'stdout': '', 'stderr': ''};
  }
};

CodeOceanEditorRequestForComments = {
  requestComments: function () {
    var user_id = $('#editor').data('user-id');
    var exercise_id = $('#editor').data('exercise-id');
    var file_id = $('.editor').data('id');
    var question = $('#question').val();

    var createRequestForComments = function (submission) {
      $.ajax({
        method: 'POST',
        url: '/request_for_comments',
        data: {
          request_for_comment: {
            exercise_id: exercise_id,
            file_id: file_id,
            submission_id: submission.id,
            question: question
          }
        }
      }).done(function () {
        this.hideSpinner();
        $.flash.success({text: $('#askForCommentsButton').data('message-success')});
        // trigger a run
        this.runSubmission.call(this, submission);
      }.bind(this)).error(this.ajaxError.bind(this));
    };

    this.createSubmission($('#requestComments'), null, createRequestForComments.bind(this));

    $('#comment-modal').modal('hide');
    // we disabled the button to prevent that the user spams RFCs, but decided against this now.
    //var button = $('#requestComments');
    //button.prop('disabled', true);
  },
};