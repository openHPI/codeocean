$(function() {
  var ACE_FILES_PATH = '/assets/ace/';
  var ADEQUATE_PERCENTAGE = 50;
  var ALT_1_KEY_CODE = 161;
  var ALT_2_KEY_CODE = 8220;
  var ALT_3_KEY_CODE = 182;
  var ALT_4_KEY_CODE = 162;
  var ALT_R_KEY_CODE = 174;
  var ALT_S_KEY_CODE = 8218;
  var ALT_T_KEY_CODE = 8224;
  var FILENAME_URL_PLACEHOLDER = '{filename}';
  var SUCCESSFULL_PERCENTAGE = 90;
  var THEME = 'ace/theme/textmate';

  var editors = [];
  var active_file;
  var active_frame;
  var running = false;

  var flowrUrl = 'http://vm-teusner-webrtc.eaalab.hpi.uni-potsdam.de:3000/api/exceptioninfo?id=&lang=auto'
  var flowrResultHtml = '<div class="panel panel-default"><div id="{{headingId}}" role="tab" class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#flowrHint" href="#{{collapseId}}" aria-expanded="true" aria-controls="{{collapseId}}"></a></h4></div><div id="{{collapseId}}" role="tabpanel" aria-labelledby="{{headingId}}" class="panel-collapse collapse"><div class="panel-body"></div></div></div>'

  var ajax = function(options) {
    return $.ajax(_.extend({
      dataType: 'json',
      method: 'POST',
    }, options));
  };

  var ajaxError = function(response) {
    var message = ((response || {}).responseJSON || {}).message || '';

    $.flash.danger({
      text: message.length > 0 ? message : $('#flash').data('message-failure')
    });
  };

  var clearOutput = function() {
    $('#output pre').remove();
  };

  var closeEventSource = function(event) {
    event.target.close();
    hideSpinner();
    running = false;
    toggleButtonStates();

    if (event.type === 'error' || JSON.parse(event.data).code !== 200) {
      ajaxError();
      showTab(1);
    }
  };

  var collectFiles = function() {
    var editable_editors = _.filter(editors, function(editor) {
      return !editor.getReadOnly();
    });
    return _.map(editable_editors, function(editor) {
      return {
        content: editor.getValue(),
        file_id: $(editor.container).data('file-id')
      };
    });
  };

  var configureEditors = function() {
    _.each(['modePath', 'themePath', 'workerPath'], function(attribute) {
      ace.config.set(attribute, ACE_FILES_PATH);
    });
  };

  var confirmDestroy = function(event) {
    event.preventDefault();
    if (confirm($(this).data('message-confirm'))) {
      destroyFile();
    }
  };

  var confirmReset = function(event) {
    event.preventDefault();
    if (confirm($(this).data('message-confirm'))) {
      resetCode();
    }
  };

  var confirmSubmission = function(event) {
    event.preventDefault();
    if (confirm($(this).data('message-confirm'))) {
      submitCode();
    }
  };

  var createSubmission = function(initiator, filter, callback) {
    showSpinner(initiator);
    var jqxhr = ajax({
      data: {
        submission: {
          cause: $(initiator).data('cause') || $(initiator).prop('id'),
          exercise_id: $('#editor').data('exercise-id'),
          files_attributes: (filter || _.identity)(collectFiles())
        }
      },
      url: $(initiator).data('url') || $('#editor').data('submissions-url')
    });
    jqxhr.always(hideSpinner);
    jqxhr.done(callback);
    jqxhr.fail(ajaxError);
  };

  var destroyFile = function() {
    createSubmission($('#destroy-file'), function(files) {
      return _.reject(files, function(file) {
        return file.file_id === active_file.id;
      });
    }, window.CodeOcean.refresh);
  };

  var downloadCode = function(event) {
    event.preventDefault();
    createSubmission(this, null,function(response) {
      var url = response.download_url.replace(FILENAME_URL_PLACEHOLDER, active_file.filename);
      window.location = url;
    });
  };

  var evaluateCode = function(url, streamed, callback) {
    (streamed ? evaluateCodeWithStreamedResponse : evaluateCodeWithoutStreamedResponse)(url, callback);
  };

  var evaluateCodeWithStreamedResponse = function(url, callback) {
    var event_source = new EventSource(url);

    event_source.addEventListener('close', closeEventSource);
    event_source.addEventListener('error', closeEventSource);
    event_source.addEventListener('hint', renderHint);
    event_source.addEventListener('info', storeContainerInformation);
    event_source.addEventListener('output', callback);
    event_source.addEventListener('start', callback);

    if ($('#flowrHint').isPresent()) {
      event_source.addEventListener('output', handleStderrOutputForFlowr);
      event_source.addEventListener('close', handleStderrOutputForFlowr);
    }

    event_source.addEventListener('status', function(event) {
      showStatus(JSON.parse(event.data));
    });
  };

  var evaluateCodeWithoutStreamedResponse = function(url, callback) {
    var jqxhr = ajax({
      method: 'GET',
      url: url
    });
    jqxhr.always(hideSpinner);
    jqxhr.done(callback);
    jqxhr.fail(ajaxError);
  };

  var fileActionsAvailable = function() {
    return isActiveFileRenderable() || isActiveFileRunnable() || isActiveFileStoppable() || isActiveFileTestable();
  };

  var findOrCreateOutputElement = function(index) {
    if ($('#output-' + index).isPresent()) {
      return $('#output-' + index);
    } else {
      var element = $('<pre>').attr('id', 'output-' + index);
      $('#output').append(element);
      return element;
    }
  };

  var getPanelClass = function(result) {
    if (result.stderr && !result.score) {
      return 'panel-danger';
    } else if (result.score < 1) {
      return 'panel-warning';
    } else {
      return 'panel-success';
    }
  };

  var getProgressBarClass = function(percentage) {
    if (percentage < ADEQUATE_PERCENTAGE) {
      return 'progress-bar progress-bar-striped progress-bar-danger';
    } else if (percentage < SUCCESSFULL_PERCENTAGE) {
      return 'progress-bar progress-bar-striped progress-bar-warning';
    } else {
      return 'progress-bar progress-bar-striped progress-bar-success';
    }
  };

  var handleKeyPress = function(event) {
    if (event.which === ALT_1_KEY_CODE) {
      showTab(0);
    } else if (event.which === ALT_2_KEY_CODE) {
      showWorkspaceTab(event);
    } else if (event.which === ALT_3_KEY_CODE) {
      showTab(2);
    } else if (event.which === ALT_4_KEY_CODE) {
      showTab(3);
    } else if (event.which === ALT_R_KEY_CODE) {
      $('#run').trigger('click');
    } else if (event.which === ALT_S_KEY_CODE) {
      $('#assess').trigger('click');
    } else if (event.which === ALT_T_KEY_CODE) {
      $('#test').trigger('click');
    } else {
      return;
    }
    event.preventDefault();
  };

  var handleScoringResponse = function(response) {
    printScoringResults(response);
    var score = _.reduce(response, function(sum, result) {
      return sum + result.score * result.weight;
    }, 0).toFixed(2);
    $('#score').data('score', score);
    renderScore();
    showTab(3);
  };

  var stderrOutput = ''
  var handleStderrOutputForFlowr = function(event) {
    var json = JSON.parse(event.data);

    if (json.stderr) {
      stderrOutput += json.stderr;
    } else if (json.code) {
      if (stderrOutput == '') {
        return
      }

      var flowrHintBody = $('#flowrHint .panel-body')
      var queryParameters = {
        query: stderrOutput
      }

      flowrHintBody.empty()

      jQuery.getJSON(flowrUrl, queryParameters, function(data) {
        for (var question in data.queryResults) {
          var collapsibleTileHtml = flowrResultHtml.replace(/{{collapseId}}/g, 'collapse-' + question).replace(/{{headingId}}/g, 'heading-' + question)
          var resultTile = $(collapsibleTileHtml)

          resultTile.find('h4 > a').text(data.queryResults[question].title + ' | Found via ' + data.queryResults[question].source)
          resultTile.find('.panel-body').html(data.queryResults[question].body)
          resultTile.find('.panel-body').append('<a href="' + data.queryResults[question].url  + '" class="btn btn-primary btn-block">Open this question</a>')

          flowrHintBody.append(resultTile)
        }

        if (data.queryResults.length !== 0) {
          $('#flowrHint').fadeIn()
        }
      })

      stderrOutput = ''
    }
  };

  var handleTestResponse = function(response) {
    clearOutput();
    printOutput(response[0], false, 0);
    showStatus(response[0]);
    showTab(2);
  };

  var hideSpinner = function() {
    $('button i.fa').show();
    $('button i.fa-spin').hide();
  };

  var initializeEditors = function() {
    $('.editor').each(function(index, element) {
      var editor = ace.edit(element);
      editor.setReadOnly($(element).data('read-only') !== undefined);
      editor.setShowPrintMargin(false);
      editor.setTheme(THEME);
      editors.push(editor);
      var session = editor.getSession();
      session.setMode($(element).data('mode'));
      session.setTabSize($(element).data('indent-size'));
      session.setUseSoftTabs(true);
      session.setUseWrapMode(true);

      var file_id =  $(element).data('file-id');
      setAnnotations(editor, file_id);

      session.on('annotationRemoval', handleAnnotationRemoval)
      session.on('annotationChange', handleAnnotationChange)

      // TODO refactor here
      // Code for clicks on gutter / sidepanel
      editor.on("guttermousedown", function(e){
        var target = e.domEvent.target;
        if (target.className.indexOf("ace_gutter-cell") == -1)
          return;
        if (!editor.isFocused())
          return;
        if (e.clientX > 25 + target.getBoundingClientRect().left)
          return;


        var row = e.getDocumentPosition().row;
        e.stop();

        var commentModal = $('#comment-modal')

        if (hasCommentsInRow(editor, row)) {
          var rowComments = getCommentsForRow(editor, row)
          var comments = _.pluck(rowComments, 'text').join('\n')
          commentModal.find('#other-comments').text(comments)
        } else {
          commentModal.find('#other-comments').text('none')
        }

        commentModal.find('#addCommentButton').off('click')
        commentModal.find('#removeAllButton').off('click')

        commentModal.find('#addCommentButton').on('click', function(e){
          var user_id = 18
          var commenttext = commentModal.find('textarea').val()

          if (commenttext !== "") {
            createComment(user_id, file_id, row, editor, commenttext)
            commentModal.modal('hide')
          }
        })

        commentModal.find('#removeAllButton').on('click', function(e){
          var user_id = 18;
          deleteComment(user_id,file_id,row,editor);
          commentModal.modal('hide')
        })

        commentModal.modal('show')
      });
    });
  };

    var hasCommentsInRow = function (editor, row){
    return editor.getSession().getAnnotations().some(function(element) {
      return element.row === row
    })
  }

  var getCommentsForRow = function (editor, row){
    return editor.getSession().getAnnotations().filter(function(element) {
      return element.row === row
    })
  }

  var setAnnotations = function (editor, file_id){

      var session = editor.getSession();

      // Retrieve comments for file and set them as annotations
      var url = "/comments";

      var jqrequest = $.ajax({
          dataType: 'json',
          method: 'GET',
          url: url,
          data: {
            file_id: file_id
          }
      });

      jqrequest.done(function(response){
          setAnnotationsCallback(response, session);
      });
      jqrequest.fail(ajaxError);
  }

  var setAnnotationsCallback = function (response, session) {
      var annotations = response;

      $.each(annotations, function(index, comment){
          comment.className = "code-ocean_comment";
          comment.text = comment.user_id + ": " + comment.text;
      });

      session.setAnnotations(annotations);
  }

  var deleteComment = function (user_id, file_id, row, editor) {
      var jqxhr = $.ajax({
          type: 'DELETE',
          url: "/comments",
          data: {
            row: row,
            file_id: file_id,
            user_id: user_id
          }
      });
      jqxhr.done(function (response) {
          setAnnotations(editor, file_id);
      });
      jqxhr.fail(ajaxError);
  }

  var createComment = function (user_id, file_id, row, editor, commenttext){
      var jqxhr = $.ajax({
        data: {
          comment: {
            user_id: user_id,
            file_id: file_id,
            row: row,
            column: 0,
            text: commenttext
          }
        },
        dataType: 'json',
        method: 'POST',
        url:  "/comments"
      });
      jqxhr.done(function(response){
          setAnnotations(editor, file_id);
      });
      jqxhr.fail(ajaxError);
  }

  var handleAnnotationRemoval = function(removedAnnotations) {
    removedAnnotations.forEach(function(annotation) {
      $.ajax({
        method: 'DELETE',
        url:  '/comment_by_id',
        data: {
          id: annotation.id,
        }
      })
    })
  }

  var handleAnnotationChange = function(changedAnnotations) {
    changedAnnotations.forEach(function(annotation) {
      $.ajax({
        method: 'PUT',
        url:  '/comments',
        data: {
          id: annotation.id,
          user_id: 18,
          comment: {
            row: annotation.row,
            text: annotation.text
          }
        }
      })
    })
  }

  var initializeEventHandlers = function() {
    $(document).on('click', '#results a', showOutput);
    $(document).on('keypress', handleKeyPress);
    $('a[data-toggle="tab"]').on('show.bs.tab', storeTab);
    initializeFileTreeButtons();
    initializeWorkflowButtons();
    initializeWorkspaceButtons();
  };

  var initializeFileTree = function() {
    $('#files').jstree($('#files').data('entries'));
    $('#files').on('click', 'li.jstree-leaf', function() {
      active_file = {
        filename: $(this).text(),
        id: parseInt($(this).attr('id'))
      };
      var frame = $('[data-file-id="' + active_file.id + '"]').parent();
      showFrame(frame);
      toggleButtonStates();
    });
  };

  var initializeFileTreeButtons = function() {
    $('#create-file').on('click', showFileDialog);
    $('#destroy-file').on('click', confirmDestroy);
    $('#download').on('click', downloadCode);
  };

  var initializeTooltips = function() {
    $('[data-tooltip]').tooltip();
  };

  var initializeWorkflowButtons = function() {
    $('#start').on('click', showWorkspaceTab);
    $('#submit').on('click', confirmSubmission);
  };

  var initializeWorkspaceButtons = function() {
    $('#assess').on('click', scoreCode);
    $('#dropdown-render, #render').on('click', renderCode);
    $('#dropdown-run, #run').on('click', runCode);
    $('#dropdown-stop, #stop').on('click', stopCode);
    $('#dropdown-test, #test').on('click', testCode);
    $('#save').on('click', saveCode);
    $('#start-over').on('click', confirmReset);
  };

  var isActiveFileExecutable = function() {
    return 'executable' in active_frame.data();
  };

  var isActiveFileRenderable = function() {
    return 'renderable' in active_frame.data();
  };

  var isActiveFileRunnable = function() {
    return isActiveFileExecutable() && ['main_file', 'user_defined_file'].includes(active_frame.data('role'));
  };

  var isActiveFileStoppable = function() {
    return isActiveFileRunnable() && running;
  };

  var isActiveFileTestable = function() {
    return isActiveFileExecutable() && ['teacher_defined_test', 'user_defined_test'].includes(active_frame.data('role'));
  };

  var isBrowserSupported = function() {
    return window.EventSource !== undefined;
  };

  var populatePanel = function(panel, result, index) {
    panel.removeClass('panel-default').addClass(getPanelClass(result));
    panel.find('.panel-title .filename').text(result.filename);
    panel.find('.panel-title .number').text(index + 1);
    panel.find('.row .col-sm-9').eq(0).find('.number').eq(0).text(result.passed);
    panel.find('.row .col-sm-9').eq(0).find('.number').eq(1).text(result.count);
    panel.find('.row .col-sm-9').eq(1).find('.number').eq(0).text((result.score * result.weight).toFixed(2));
    panel.find('.row .col-sm-9').eq(1).find('.number').eq(1).text(result.weight);
    panel.find('.row .col-sm-9').eq(2).text(result.message);
    panel.find('.row .col-sm-9').eq(3).find('a').attr('href', '#output-' + index);
  };

  var printChunk = function(event) {
    var output = JSON.parse(event.data);
    if (output) {
      printOutput(output, true, 0);
    } else {
      clearOutput();
      $('#hint').fadeOut();
      $('#flowrHint').fadeOut();
      showTab(2);
    }
  };

  var printOutput = function(output, colorize, index) {
    var element = findOrCreateOutputElement(index);
    if (!colorize) {
      var stream = _.sortBy([output.stderr || '', output.stdout || ''], function(stream) {
        return stream.length;
      })[1];
      element.append(stream);
    } else if (output.stderr) {
      element.addClass('text-warning').append(output.stderr);
    } else if (output.stdout) {
      element.addClass('text-success').append(output.stdout);
    } else {
      element.addClass('text-muted').text($('#output').data('message-no-output'));
    }
  };

  var printScoringResult = function(result, index) {
    $('#results').show();
    var panel = $('#dummies').children().first().clone();
    populatePanel(panel, result, index);
    $('#results ul').first().append(panel);
  };

  var printScoringResults = function(response) {
    $('#results ul').first().html('');
    $('.test-count .number').html(response.length);
    clearOutput();
    _.each(response, function(result, index) {
      printOutput(result, false, index);
      printScoringResult(result, index);
    });
  };

  var renderCode = function(event) {
    event.preventDefault();
    if ($('#render').is(':visible')) {
      createSubmission(this, null, function(response) {
        var url = response.render_url.replace(FILENAME_URL_PLACEHOLDER, active_file.filename);
        var pop_up_window = window.open(url);
        if (pop_up_window) {
          pop_up_window.onerror = function(message) {
            clearOutput();
            printOutput({
              stderr: message
            }, true, 0);
            sendError(message);
            showTab(2);
          };
        }
      });
    }
  };

  var renderHint = function(object) {
    var hint = object.data || object.hint;
    if (hint) {
      $('#hint .panel-body').text(hint);
      $('#hint').fadeIn();
    }
  };

  var renderProgressBar = function(score, maximum_score) {
    var percentage = score / maximum_score * 100;
    var progress_bar = $('#score .progress-bar');
    progress_bar.removeClass().addClass(getProgressBarClass(percentage));
    progress_bar.attr({
      'aria-valuemax': maximum_score,
      'aria-valuemin': 0,
      'aria-valuenow': score
    });
    progress_bar.css('width', percentage + '%');
  };

  var renderScore = function() {
    var score = $('#score').data('score');
    var maxium_score = $('#score').data('maximum-score');
    $('.score').html((score || '?') + ' / ' + maxium_score);
    renderProgressBar(score, maxium_score);
  };

  var resetCode = function() {
    showSpinner(this);
    ajax({
      method: 'GET',
      url: $('#start-over').data('url')
    }).success(function(response) {
      hideSpinner();
      _.each(editors, function(editor) {
        var file_id = $(editor.container).data('file-id');
        var file = _.find(response.files, function(file) {
          return file.id === file_id;
        });
        editor.setValue(file.content);
      });
    });
  };

  var runCode = function(event) {
    event.preventDefault();
    if ($('#run').is(':visible')) {
      createSubmission(this, null, function(response) {
        $('#stop').data('url', response.stop_url);
        running = true;
        showSpinner($('#run'));
        toggleButtonStates();
        var url = response.run_url.replace(FILENAME_URL_PLACEHOLDER, active_file.filename);
        evaluateCode(url, true, printChunk);
      });
    }
  };

  var saveCode = function(event) {
    event.preventDefault();
    createSubmission(this, null, function() {
      $.flash.success({
        text: $('#save').data('message-success')
      });
    });
  };

  var sendError = function(message) {
    showSpinner($('#render'));
    var jqxhr = ajax({
      data: {
        error: {
          message: message
        }
      },
      url: $('#editor').data('errors-url')
    });
    jqxhr.always(hideSpinner);
    jqxhr.success(renderHint);
  };

  var scoreCode = function(event) {
    event.preventDefault();
    createSubmission(this, null, function(response) {
      showSpinner($('#assess'));
      var url = response.score_url;
      evaluateCode(url, false, handleScoringResponse);
    });
  };

  var showFileDialog = function(event) {
    event.preventDefault();
    createSubmission(this, null, function(response) {
      $('#code_ocean_file_context_id').val(response.id);
      $('#modal-file').modal('show');
    });
  };

  var showFirstFile = function() {
    var frame = $('.frame[data-role="main_file"]').isPresent() ? $('.frame[data-role="main_file"]') : $('.frame').first();
    var file_id = frame.find('.editor').data('file-id');
    active_file = {
      filename: frame.data('filename'),
      id: file_id
    };
    $('#files').jstree().select_node(file_id);
    showFrame(frame);
    toggleButtonStates();
  };

  var showFrame = function(frame) {
    active_frame = frame;
    $('.frame').hide();
    frame.show();
  };

  var showOutput = function(event) {
    event.preventDefault();
    showTab(2);
    $('#output').scrollTo($(this).attr('href'));
  };

  var showRequestedTab = function() {
    var regexp = /tab=(\d+)/;
    if (regexp.test(window.location.search)) {
      var index = regexp.exec(window.location.search)[1] - 1;
    } else {
      var index = localStorage.tab;
    }
    showTab(index);
  };

  var showSpinner = function(initiator) {
    $(initiator).find('i.fa').hide();
    $(initiator).find('i.fa-spin').show();
  };

  var showStatus = function(output) {
    if (output.status === 'timeout') {
      $.flash.danger({
        icon: ['fa', 'fa-clock-o'],
        text: $('#editor').data('message-timeout')
      });
    } else if (output.stderr) {
      $.flash.danger({
        icon: ['fa', 'fa-bug'],
        text: $('#run').data('message-failure')
      });
    } else {
      $.flash.success({
        icon: ['fa', 'fa-check'],
        text: $('#run').data('message-success')
      });
    }
  };

  var showTab = function(index) {
    $('a[data-toggle="tab"]').eq(index || 0).tab('show');
  };

  var showWorkspaceTab = function(event) {
    event.preventDefault();
    showTab(1);
  };

  var stopCode = function(event) {
    event.preventDefault();
    if ($('#stop').is(':visible')) {
      var jqxhr = ajax({
        data: {
          container_id: $('#stop').data('container').id
        },
        url: $('#stop').data('url')
      });
      jqxhr.always(function() {
        hideSpinner();
        running = false;
        toggleButtonStates();
      });
      jqxhr.fail(ajaxError);
    }
  };

  var storeContainerInformation = function(event) {
    var container_information = JSON.parse(event.data);
    $('#stop').data('container', container_information);

    if (_.size(container_information.port_bindings) > 0) {
      $.flash.info({
        icon: ['fa', 'fa-exchange'],
        text: _.map(container_information.port_bindings, function(key, value) {
          var url = window.location.protocol + '//' + window.location.hostname + ':' + key;
          return $('#run').data('message-network').replace('%{port}', value).replace(/%{address}/g, url);
        }).join('\n')
      });
    }
  };

  var storeTab = function(event) {
    localStorage.tab = $(event.target).parent().index();
  };

  var submitCode = function() {
    createSubmission($('#submit'), null, function(response) {
      if (response.redirect) {
        localStorage.removeItem('tab');
        window.location = response.redirect;
      }
    });
  };

  var testCode = function(event) {
    event.preventDefault();
    if ($('#test').is(':visible')) {
      createSubmission(this, null, function(response) {
        showSpinner($('#test'));
        var url = response.test_url.replace(FILENAME_URL_PLACEHOLDER, active_file.filename);
        evaluateCode(url, false, handleTestResponse);
      });
    }
  };

  var toggleButtonStates = function() {
    $('#destroy-file').prop('disabled', active_frame.data('role') !== 'user_defined_file');
    $('#dropdown-render').toggleClass('disabled', !isActiveFileRenderable());
    $('#dropdown-run').toggleClass('disabled', !isActiveFileRunnable() || running);
    $('#dropdown-stop').toggleClass('disabled', !isActiveFileStoppable());
    $('#dropdown-test').toggleClass('disabled', !isActiveFileTestable());
    $('#dummy').toggle(!fileActionsAvailable());
    $('#editor-buttons .dropdown-toggle').toggle(fileActionsAvailable());
    $('#render').toggle(isActiveFileRenderable());
    $('#run').toggle(isActiveFileRunnable() && !running);
    $('#stop').toggle(isActiveFileStoppable());
    $('#test').toggle(isActiveFileTestable());
  };

  if ($('#editor').isPresent()) {
    if (isBrowserSupported()) {
      $('.score, #development-environment').show();
      configureEditors();
      initializeEditors();
      initializeEventHandlers();
      initializeFileTree();
      initializeTooltips();
      renderScore();
      showFirstFile();
      showRequestedTab();
    } else {
      $('#alert').show();
    }
  }
});
