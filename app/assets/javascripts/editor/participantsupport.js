CodeOceanEditorFlowr = {
  flowrResultHtml:
    '<div class="card mb-2">' +
      '<div id="{{headingId}}" role="tab" class="card-header">' +
        '<div class="card-title mb-0">' +
          '<a class="collapsed" data-bs-toggle="collapse" data-bs-parent="#flowrHint" href="#{{collapseId}}" aria-expanded="false" aria-controls="{{collapseId}}">' +
            '<div class="clearfix" role="button">' +
              '<i class="fa-solid" aria-hidden="true"></i>' +
              '<span>' +
              '</span>' +
            '</div>' +
          '</a>' +
        '</div>' +
      '</div>' +
      '<div id="{{collapseId}}" role="tabpanel" aria-labelledby="{{headingId}}" class="card card-collapse collapse">' +
        '<div class="card-body d-grid gap-2"></div>' +
      '</div>' +
    '</div>',

  getFlowrSettings: function () {
    if (this._flowrSettings === undefined) {
      this._flowrSettings = $('#editor').data('flowr');
    }
    return this._flowrSettings;
  },

  getInsights: function () {
    var stackOverflowUrl = 'https://api.stackexchange.com/2.2/search/advanced';

    return jQuery.ajax({
      dataType: "json",
      url: Routes.insights_path(),
      data: {}
    }).then(function (insights) {
      var stackoverflowRequests = _.map(insights, function (insight) {
        var queryParams = {
          accepted: true,
          pagesize: this.getFlowrSettings().answers_per_query,
          order: 'desc',
          sort: 'relevance',
          site: 'stackoverflow',
          answers: 1,
          filter: '!23qca9v**HCO.ESF)dHfT', // title, body, accepted answer
          q: insight.query
        }

        return jQuery.ajax({
          dataType: "json",
          url: stackOverflowUrl,
          data: queryParams
        }).promise();
      }.bind(this));
      return jQuery.when.apply(jQuery, stackoverflowRequests);
    }.bind(this));
  },
  collectResults: function(response) {
    var results = [];
    var addToResultsIfSuccessful = function (data, textStatus, jqXHR) {
      if (jqXHR && jqXHR.status === 200) {
        _.each(data.items, function (item) {
          if (!_.contains(results, item)) {
            results.push(item);
          }
        });
      }
    }

    if (_.isArray(response[0])) {
      // multiple queries
      _.each(response, function (args) {
        addToResultsIfSuccessful.apply(this, args)
      });
    } else {
      // single query
      addToResultsIfSuccessful.apply(this, response);
    }
    return results;
  },
  handleStderrOutputForFlowr: function () {
    if (! this.getFlowrSettings()?.enabled) return;

    var flowrHintBody = $('#flowrHint .card-body');
    flowrHintBody.empty();
    var self = this;

    this.getInsights().then(function () {
      var results = self.collectResults(arguments);
      _.each(results, function (result, index) {
        var collapsibleTileHtml = self.flowrResultHtml
          .replace(/{{collapseId}}/g, 'collapse-' + index).replace(/{{headingId}}/g, 'heading-' + index);
        var resultTile = $(collapsibleTileHtml);
        var questionUrl = 'https://stackoverflow.com/questions/' + result.question_id;

        var header = resultTile.find('span');
        header.text(result.title);
        header.on('click', CodeOceanEditor.createEventHandler('editor_flowr_expand_question', questionUrl));

        var body = resultTile.find('.card-body');
        body.html(result.body);
        body.append('<a target="_blank" href="' + questionUrl + '" class="btn btn-primary">' +
          `${I18n.t('exercises.implement.flowr.go_to_question')}</a>`);
        body.find('.btn').on('click', CodeOceanEditor.createEventHandler('editor_flowr_click_question', questionUrl));

        flowrHintBody.append(resultTile);
      });

      if (results.length > 0) {
        $('#flowrHint').fadeIn();
      }
    });
  }
};

CodeOceanEditorRequestForComments = {
  requestComments: function () {
    const cause = $('#requestComments');
    this.newSentryTransaction(cause, async () => {
      const editor = $('#editor')
      const questionElement = $('#question')
      const closeAskForCommentsButton = $('#closeAskForCommentsButton');
      const askForCommentsButton = $('#askForCommentsButton');
      const commentModal = $('#comment-modal');

      questionElement.prop("disabled", true);
      closeAskForCommentsButton.addClass('d-none');

      const exercise_id = editor.data('exercise-id');
      const file_id = $('.editor').data('id');
      const question = questionElement.val();

      const submission = await this.createSubmission(cause, null).catch((response) => {
        this.ajaxError(response);
        askForCommentsButton.one('click', this.requestComments.bind(this));
        questionElement.prop("disabled", false);
        closeAskForCommentsButton.removeClass('d-none');
      });
      if (!submission) return;

      this.showSpinner(askForCommentsButton);
      await this.stopCode();
      // Since `stopCode` might call `hideSpinner`, we need to show it again.
      this.showSpinner(askForCommentsButton);

      const response = await $.ajax({
        method: 'POST',
        url: Routes.request_for_comments_path(),
        data: {
          request_for_comment: {
            exercise_id: exercise_id,
            file_id: file_id,
            submission_id: submission.id,
            question: question
          }
        }
      }).catch(this.ajaxError.bind(this));

      bootstrap.Modal.getInstance(commentModal)?.hide();
      this.hideSpinner();
      questionElement.prop("disabled", false).val('');
      closeAskForCommentsButton.removeClass('d-none');
      askForCommentsButton.one('click', this.requestComments.bind(this));

      // we disabled the button to prevent that the user spams RFCs, but decided against this now.
      //var button = $('#requestComments');
      //button.prop('disabled', true);

      if (response) {
        await this.runSubmission(submission);
        $.flash.success({text: askForCommentsButton.data('message-success')});
      }
    });
  }
};

CodeOceanEditorTips = {
    initializeEventHandlers: function() {
        const card_headers = $('#tips .card-collapse');
        for (let tip of card_headers) {
            tip = $(tip)
            tip.on('show.bs.collapse',
                CodeOceanEditor.createEventHandler('editor_show_tip', tip.data('exercise-tip-id')));
            tip.on('hide.bs.collapse',
                CodeOceanEditor.createEventHandler('editor_hide_tip', tip.data('exercise-tip-id')));
        }
    }
}
