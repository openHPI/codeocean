CodeOceanEditorSubmissions = {
  FILENAME_URL_PLACEHOLDER: '{filename}',

  AUTOSAVE_INTERVAL: 15 * 1000,
  autosaveTimer: null,
  autosaveLabel: "#statusbar span",

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
      url: url + '.json'
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

  createSubmissionCallback: function(data){
    // set all frames context types to submission
    $('.frame').each(function(index, element) {
      $(element).data('context-type', 'Submission');
    });

    // update the ids of the editors and reload the annotations
    for (var i = 0; i < this.editors.length; i++) {

      // set the data attribute to submission
      //$(editors[i].container).data('context-type', 'Submission');

      var file_id_old = $(this.editors[i].container).data('file-id');

      // file_id_old is always set. Either it is a reference to a teacher supplied given file, or it is the actual id of a new user created file.
      // This is the case, since it is set via a call to ancestor_id on the model, which returns either file_id if set, or id if it is not set.
      // therefore the else part is not needed any longer...

      // if we have an file_id set (the file is a copy of a teacher supplied given file) and the new file-ids are present in the response
      if (file_id_old != null && data.files){
        // if we find file_id_old (this is the reference to the base file) in the submission, this is the match
        for(var j = 0; j< data.files.length; j++){
          if(data.files[j].file_id === file_id_old){
            //$(editors[i].container).data('id') = data.files[j].id;
            $(this.editors[i].container).data('id', data.files[j].id );
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
    this.createSubmission('#download', null,function(response) {
      var url = response.download_url;

      // to download just a single file, use the following url
      //var url = response.download_file_url.replace(FILENAME_URL_PLACEHOLDER, active_file.filename);
      window.location = url;
    });
  },

  resetCode: function(initiator, onlyActiveFile = false) {
    this.showSpinner(initiator);
    this.ajax({
      method: 'GET',
      url: $('#start-over').data('url') || $('#start-over-active-file').data('url')
    }).done(function(response) {
      this.hideSpinner();
      _.each(this.editors, function(editor) {
        var file_id = $(editor.container).data('file-id');
        var file = _.find(response.files, function(file) {
          return file.id === file_id;
        });
        if(file && !onlyActiveFile || file && file.id === CodeOceanEditor.active_file.id){
            editor.setValue(file.content);
        }
      }.bind(this));
    }.bind(this));
  },

  renderCode: function(event) {
    event.preventDefault();
    if ($('#render').is(':visible')) {
      this.createSubmission('#render', null, function (response) {
        if (response.render_url === undefined) return;

        const active_file = CodeOceanEditor.active_file.filename.replace(/#$/,''); // remove # if it is the last character, this is not part of the filename and just an anchor
        const desired_file = response.render_url.filter(hash => hash.filepath === active_file);
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
              this.sendError(message, response.id);
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
    event.preventDefault();
    this.stopCode(event);
    if ($('#run').is(':visible')) {
      this.createSubmission('#run', null, this.runSubmission.bind(this));
    }
  },

  runSubmission: function (submission) {
    //Run part starts here
    this.running = true;
    this.showSpinner($('#run'));
    $('#score_div').addClass('d-none');
    this.toggleButtonStates();
    const url = submission.run_url.replace(this.FILENAME_URL_PLACEHOLDER, CodeOceanEditor.active_file.filename.replace(/#$/,'')); // remove # if it is the last character, this is not part of the filename and just an anchor
    this.initializeSocketForRunning(url);
  },

  saveCode: function(event) {
    event.preventDefault();
    this.createSubmission('#save', null, function() {
      $.flash.success({
        text: $('#save').data('message-success')
      });
    });
  },

  testCode: function(event) {
    event.preventDefault();
    if ($('#test').is(':visible')) {
      this.createSubmission('#test', null, function(response) {
        this.showSpinner($('#test'));
        $('#score_div').addClass('d-none');
        var url = response.test_url.replace(this.FILENAME_URL_PLACEHOLDER, CodeOceanEditor.active_file.filename.replace(/#$/,'')); // remove # if it is the last character, this is not part of the filename and just an anchor
        this.initializeSocketForTesting(url);
      }.bind(this));
    }
  },

  submitCode: function(event) {
    const button = $(event.target) || $('#submit');
    this.teardownEventHandlers();
    this.createSubmission(button, null, function (response) {
      if (response.redirect) {
        this.autosaveIfChanged();
        this.stopCode(event);
        this.editors = [];
        Turbolinks.clearCache();
        Turbolinks.visit(response.redirect);
      } else if (response.status === 'container_depleted') {
          this.showContainerDepletedMessage();
      } else if (response.message) {
          $.flash.danger({
              text: response.message
          });
      }
      this.initializeEventHandlers();
    })
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
