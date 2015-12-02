$(function() {

  var ACE_FILES_PATH = '/assets/ace/';
  var THEME = 'ace/theme/textmate';

  var active_file = undefined;

  var showFirstFile = function() {
    var frame = $('.frame[data-role="main_file"]').isPresent() ? $('.frame[data-role="main_file"]') : $('.frame').first();
    var file_id = frame.find('.editor').data('file-id');
    $('#files').jstree().select_node(file_id);
    showFrame(frame);
  };

  var showFrame = function(frame) {
    $('.frame').hide();
    frame.show();
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
    });
  };

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
      var currentSubmission = slider.val();
      var currentFiles = files[currentSubmission];

      editors.each(function(index, editor) {
        currentEditor = ace.edit(editor);
        fileContent = "";
        if (currentFiles[index]) {
          fileContent = currentFiles[index].content
        }
        currentEditor.getSession().setValue(fileContent);
      });
    });

    initializeFileTree();
    showFirstFile();
  }

});
