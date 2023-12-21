CodeOceanEditorSubmissions = {
  AUTOSAVE_INTERVAL: 15 * 1000,
  autosaveTimer: null,
  autosaveLabel: "#statusbar #autosave",

  /**
   * Submission-Creation
   */
  createSubmission: function (initiator, filter, callback) {
    const editor = $('#editor');
    this.showSpinner(initiator);
    var url = $(initiator).data('url') || editor.data('submissions-url');

    if (url === undefined) {
        const data = {
            initiator: initiator,
            filter: filter,
        }
        Sentry.captureException(JSON.stringify(data));
        return;
    }
    var jqxhr = this.ajax({
      data: {
        submission: {
          cause: $(initiator).data('cause') || $(initiator).prop('id'),
          exercise_id: editor.data('exercise-id') || $(initiator).data('exercise-id'),
          files_attributes: (filter || _.identity)(this.collectFiles())
        }
      },
      dataType: 'json',
      method: $(initiator).data('http-method') || 'POST',
      url: url,
    });
    jqxhr.always(this.hideSpinner.bind(this));
    jqxhr.done(this.createSubmissionCallback.bind(this));
    if(callback != null){
      jqxhr.done(callback.bind(this));
    }

    jqxhr.fail(this.ajaxError.bind(this));
  },

  collectFiles: function() {
    var editable_editors = _.filter(this.editors, function(editor) {
      return !editor.getReadOnly();
    });
    return _.map(editable_editors, function(editor) {
      return {
        content: editor.getValue(),
        file_id: $(editor.container).data('file-id')
      };
    });
  },

  createSubmissionCallback: function(submission){
    // update the ids of the editors and reload the annotations
    for (const editor of this.editors) {

      const file_id_old = $(editor.container).data('file-id');

      // file_id_old is always set. Either it is a reference to a teacher supplied given file, or it is the actual id of a new user created file.
      // This is the case, since it is set via a call to ancestor_id on the model, which returns either file_id if set, or id if it is not set.
      // therefore the else part is not needed any longer...

      // if we have an file_id set (the file is a copy of a teacher supplied given file) and the new file-ids are present in the submission
      if (file_id_old != null && submission.files) {
        // if we find file_id_old (this is the reference to the base file) in the submission, this is the match
        for (const file of submission.files) {
          if (file.file_id === file_id_old) {
            $(editor.container).data('id', file.id);
          }
        }
      }
    }
    // toggle button states (it might be the case that the request for comments button has to be enabled
    this.toggleButtonStates();

    this.updateSaveStateLabel();
  },

  /**
   * File-Management
   */
  destroyFile: function() {
    this.createSubmission($('#destroy-file'), function(files) {
      return _.reject(files, function(file) {
        return file.file_id === CodeOceanEditor.active_file.id;
      });
    }, window.CodeOcean.refresh);
  },

  downloadCode: function(event) {
    event.preventDefault();
    this.createSubmission('#download', null,function(submission) {
      // to download just a single file, use the following url
      // window.location = Routes.download_file_submission_url(submission.id, CodeOceanEditor.active_file.filename);
      window.location = Routes.download_submission_url(submission.id);
    });
  },

  resetCode: function(initiator, onlyActiveFile = false) {
    this.startSentryTransaction(initiator);
    this.showSpinner(initiator);
    this.ajax({
      method: 'GET',
      url: $('#start-over').data('url') || $('#start-over-active-file').data('url')
    }).done(function(response) {
      this.hideSpinner();
      App.synchronized_editor?.reset_content(response);
      this.setEditorContent(response, onlyActiveFile);
    }.bind(this));
  },

  setEditorContent: function(new_content, onlyActiveFile = false) {
    _.each(this.editors, function(editor) {
      const editor_file_id = $(editor.container).data('file-id');
      const found_file = _.find(new_content.files, function(file) {
        // File.id is used to reload the exercise and file.file_id is used to update the editor content for pair programming group members
        return (file.id || file.file_id) === editor_file_id;
      });
      if(found_file && !onlyActiveFile || found_file && found_file.id === CodeOceanEditor.active_file.id){
        editor.setValue(found_file.content);
        editor.clearSelection();
      }
    }.bind(this));
  },

  renderCode: function(event) {
    const cause = $('#render');
    this.startSentryTransaction(cause);
    event.preventDefault();
    if (cause.is(':visible')) {
      this.createSubmission(cause, null, function (submission) {
        if (submission.render_url === undefined) return;

        const active_file = CodeOceanEditor.active_file.filename;
        const desired_file = submission.render_url.filter(hash => hash.filepath === active_file);
        const url = desired_file[0].url;
        // Allow to open the new tab even in Safari.
        // See: https://stackoverflow.com/a/70463940
        setTimeout(() => {
          var pop_up_window = window.open(url, '_blank');
          if (pop_up_window) {
            pop_up_window.onerror = function (message) {
              this.clearOutput();
              this.printOutput({
                stderr: message
              }, true, 0);
              this.sendError(message, submission.id);
              this.showOutputBar();
            };
          }
        })
      });
    }
  },

  /**
   * Execution-Logic
   */
  runCode: function(event) {
    const cause = $('#run');
    this.startSentryTransaction(cause);
    event.preventDefault();
    this.stopCode(event);
    if (cause.is(':visible')) {
      this.createSubmission(cause, null, this.runSubmission.bind(this));
    }
  },

  runSubmission: function (submission) {
    //Run part starts here
    this.running = true;
    this.showSpinner($('#run'));
    $('#score_div').addClass('d-none');
    this.toggleButtonStates();
    this.initializeSocketForRunning(submission.id, CodeOceanEditor.active_file.filename);
  },

  testCode: function(event) {
    const cause = $('#test');
    this.startSentryTransaction(cause);
    event.preventDefault();
    if (cause.is(':visible')) {
      this.createSubmission(cause, null, function(submission) {
        this.showSpinner($('#test'));
        $('#score_div').addClass('d-none');
        this.initializeSocketForTesting(submission.id, CodeOceanEditor.active_file.filename);
      }.bind(this));
    }
  },

  /**
   * Autosave-Logic
   */
  resetSaveTimer: function () {
    clearTimeout(this.autosaveTimer);
    this.autosaveTimer = setTimeout(this.autosave.bind(this), this.AUTOSAVE_INTERVAL);
  },

  updateSaveStateLabel: function() {
    var date = new Date();
    var autosaveLabel = $(this.autosaveLabel);
    autosaveLabel.parent().css("visibility", "visible");
    autosaveLabel.text(date.getHours() + ':' + date.getMinutes() + ':' + date.getSeconds());
    autosaveLabel.text(date.toLocaleTimeString());
  },

  autosaveIfChanged: function() {
    // Only save if the user has changed the code in the meantime (represented by an active timer)
    if(this.autosaveTimer != null){
      this.autosave();
    }
  },

  autosave: function () {
    clearTimeout(this.autosaveTimer);
    this.autosaveTimer = null;
    this.createSubmission($('#autosave'), null);
  }
};
