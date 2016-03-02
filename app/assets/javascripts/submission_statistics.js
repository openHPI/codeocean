$(function() {

  var ACE_FILES_PATH = '/assets/ace/';
  var THEME = 'ace/theme/textmate';

  var currentSubmission = 0;
  var active_file = undefined;
  var fileTrees = []
  var editor = undefined;
  var fileTypeById = {}

  var showActiveFile = function() {
    var session = editor.getSession();
    var fileType = fileTypeById[active_file.file_type_id]
    session.setMode(fileType.editor_mode);
    session.setTabSize(fileType.indent_size);
    session.setValue(active_file.content);
    session.setUseSoftTabs(true);
    session.setUseWrapMode(true);

    showFileTree(currentSubmission);
    filetree = $(fileTrees[currentSubmission])
    filetree.jstree("deselect_all");
    filetree.jstree().select_node(active_file.file_id);
  };

  var initializeFileTree = function() {
    $('.files').each(function(index, element) {
      fileTree = $(element).jstree($(element).data('entries'));
      fileTree.on('click', 'li.jstree-leaf', function() {
        var id = parseInt($(this).attr('id'))
        _.each(files[currentSubmission], function(file) {
          if (file.file_id === id) {
            active_file = file;
          }
        });
        showActiveFile();
      });
      fileTrees.push(fileTree);
    });
  };

  var showFileTree = function(index) {
    $('.files').hide();
    $(fileTrees[index].context).show();
  }

  if ($.isController('exercises') && $('#timeline').isPresent()) {

    _.each(['modePath', 'themePath', 'workerPath'], function(attribute) {
      ace.config.set(attribute, ACE_FILES_PATH);
    });

    var slider = $('#submissions-slider>input');
    var submissions = $('#data').data('submissions');
    var files = $('#data').data('files');
    var filetypes = $('#data').data('file-types');
    var playButton = $('#play-button');
    var playInterval = undefined;

    editor = ace.edit('current-file');
    editor.setShowPrintMargin(false);
    editor.setTheme(THEME);
    editor.$blockScrolling = Infinity;
    editor.setReadOnly(true);

    _.each(filetypes, function (filetype) {
      filetype = JSON.parse(filetype);
      fileTypeById[filetype.id] = filetype;
    });

    $('tr[data-id]>.clickable').each(function(index, element) {
      element = $(element);
      element.click(function() {
        slider.val(index);
        slider.change()
      });
    });

    slider.on('change', function(event) {
      currentSubmission = slider.val();
      var currentFiles = files[currentSubmission];
      var fileIndex = 0;
      _.each(currentFiles, function(file, index) {
        if (file.name === active_file.name) {
          fileIndex = index;
        }
      })
      active_file = currentFiles[fileIndex];
      showActiveFile();
    });

    stopReplay = function() {
      clearInterval(playInterval);
      playInterval = undefined;
      playButton.find('span.fa').removeClass('fa-pause').addClass('fa-play')
    }

    playButton.on('click', function(event) {
      if (playInterval == undefined) {
        playInterval = setInterval(function() {
          if ($.isController('exercises') && $('#timeline').isPresent() && slider.val() < submissions.length - 1) {
            slider.val(parseInt(slider.val()) + 1);
            slider.change()
          } else {
            stopReplay();
          }
        }, 5000);
        playButton.find('span.fa').removeClass('fa-play').addClass('fa-pause')
      } else {
        stopReplay();
      }
    });

    active_file = files[0][0]
    initializeFileTree();
    showActiveFile();
  }

});
