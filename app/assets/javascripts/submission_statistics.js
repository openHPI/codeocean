$(document).on('turbolinks:load', function(event) {
  var currentSubmission = 0;
  var active_file = undefined;
  var fileTrees = [];
  var editor = undefined;
  var fileTypeById = {};

  var showActiveFile = function() {
    $('tr.active').removeClass('active');
    $('tr#submission-' + currentSubmission).addClass('active');
    var session = editor.getSession();
    var fileType = fileTypeById[active_file.file_type_id];
    session.setMode(fileType.editor_mode);
    session.setTabSize(fileType.indent_size);
    session.setValue(active_file.content);
    session.setUseSoftTabs(true);
    session.setUseWrapMode(true);

    // The event ready.jstree is fired too early and thus doesn't work.
    var selectFileInJsTree = function() {
      if (!filetree.hasClass('jstree-loading')) {
        filetree.jstree("deselect_all");
        filetree.jstree("select_node", active_file.file_id);
      } else {
        setTimeout(selectFileInJsTree, 250);
      }
    };

    filetree = $(fileTrees[currentSubmission]);
    selectFileInJsTree();
    // Finally change jstree element to prevent flickering
    showFileTree(currentSubmission);
  };

  var initializeFileTree = function() {
    $('.files').each(function(index, element) {
      const jsTreeConfig = $(element).data('entries')
      jsTreeConfig.core.themes = {...jsTreeConfig.core.themes, name: window.getCurrentTheme() === "dark" ? "default-dark" : "default"}
      const fileTree = $(element).jstree(jsTreeConfig);
        $(element).on('click', 'li.jstree-leaf', function() {
        var id = parseInt($(this).attr('id'));
        _.each(files[currentSubmission], function(file) {
          if (file.file_id === id) {
            active_file = file;
          }
        });
        showActiveFile();
      });
      $(document).on('theme:change', function(event) {
          const newColorScheme = event.detail.currentTheme;
          // Update the JStree theme
          fileTree.jstree(true).set_theme(newColorScheme === "dark" ? "default-dark" : "default");
      });
      fileTrees.push(fileTree);
    });
  };

  var showFileTree = function(index) {
    $('.files').hide();
    $(fileTrees[index]).show();
  };

  if ($.isController('exercises') && $('#timeline').isPresent() && event.originalEvent.data.url.includes("/statistics")) {

    _.each(['modePath', 'themePath', 'workerPath'], function(attribute) {
      ace.config.set(attribute, CodeOceanEditor.ACE_FILES_PATH);
    });

    var slider = $('#submissions-slider>input');
    var submissions = $('#data').data('submissions');
    var files = $('#data').data('files');
    var filetypes = $('#data').data('file-types');
    var playButton = $('#play-button');
    var playInterval = undefined;

    editor = ace.edit('current-file');
    editor.setShowPrintMargin(false);
    editor.setTheme(CodeOceanEditor.THEME);
    editor.$blockScrolling = Infinity;
    editor.setReadOnly(true);

    _.each(filetypes, function (filetype) {
      filetype = JSON.parse(filetype);
      fileTypeById[filetype.id] = filetype;
    });

    $('tr[data-id]>.clickable').each(function(index, element) {
      element = $(element);
      element.parent().attr('id', 'submission-' + index);
      element.click(function() {
        slider.val(index);
        slider.change()
      });
    });

    const handleAceThemeChangeEvent = function() {
        editor.setTheme(CodeOceanEditor.THEME);
    };

    $(document).on('theme:change:ace', handleAceThemeChangeEvent.bind(this));

    const onSliderChange = function(event) {
      currentSubmission = slider.val();
      var currentFiles = files[currentSubmission];
      var fileIndex = 0;
      _.each(currentFiles, function(file, index) {
        if (file.name === active_file.name) {
          fileIndex = index;
        }
      });
      active_file = currentFiles[fileIndex];
      showActiveFile();
    };

    slider.on('change', onSliderChange);

    stopReplay = function() {
      clearInterval(playInterval);
      playInterval = undefined;
      playButton.find('span.fa-solid').removeClass('fa-pause').addClass('fa-play')
    };

    playButton.on('click', function(event) {
      if (playInterval === undefined) {
        // Reset slider if showing newest submission.
        if (parseInt(slider.val()) === submissions.length - 1) {
          slider.val(0);
          onSliderChange();
        }

        playInterval = setInterval(function() {
          if ($.isController('exercises') && $('#timeline').isPresent() && slider.val() < submissions.length - 1) {
            slider.val(parseInt(slider.val()) + 1);
            slider.change()
          } else {
            stopReplay();
          }
        }, 1000);
        playButton.find('span.fa-solid').removeClass('fa-play').addClass('fa-pause')
      } else {
        stopReplay();
      }
    });

    active_file = files[0][0];
    initializeFileTree();
    showActiveFile();

    // Start with newest submission
    slider.val(submissions.length - 1);
    onSliderChange();
  }

});
