$(function() {

  var ACE_FILES_PATH = '/assets/ace/';
  var THEME = 'ace/theme/textmate';

  var currentSubmission = 0;
  var active_file = undefined;
  var fileTrees = []

  var showFirstFile = function() {
    $(fileTrees[currentSubmission]).jstree().select_node(active_file.file_id);
    showActiveFrame();
    showFileTree(currentSubmission);
  };

  var showActiveFrame = function() {
    var frame = $('.data[data-file-id="' + active_file.id + '"]').parent().find('.frame');
    $('.frame').hide();
    frame.show();
  };

  var initializeFileTree = function() {
    $('.files').each(function(index, element) {
      fileTree = $(element).jstree($(element).data('entries'));
      fileTree.on('click', 'li.jstree-leaf', function() {
        active_file = {
          filename: $(this).text(),
          id: parseInt($(this).attr('id'))
        };
        showActiveFrame()
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

    var editors = $('.editor');
    var slider = $('#slider>input');
    var submissions = $('#data').data('submissions');
    var files = $('#data').data('files');

    editors.each(function(index, element) {
      currentEditor = ace.edit(element);

      var file_id = $(element).data('file-id');
      var content = $('.editor-content[data-file-id=' + file_id + ']');

      currentEditor.setShowPrintMargin(false);
      currentEditor.setTheme(THEME);
      currentEditor.$blockScrolling = Infinity;
      currentEditor.setReadOnly(true);

      var session = currentEditor.getSession();
      session.setMode($(element).data('mode'));
      session.setTabSize($(element).data('indent-size'));
      session.setUseSoftTabs(true);
      session.setUseWrapMode(true);
      session.setValue(content.text());
    });

    slider.on('change', function(event) {
      currentSubmission = slider.val();
      showFileTree(currentSubmission);
      var currentFiles = files[currentSubmission];
      console.log(currentFiles);
      active_file = currentFiles[0];
      showFirstFile();
    });

    active_file = files[0][0]
    initializeFileTree();
    showFirstFile();
  }

});
