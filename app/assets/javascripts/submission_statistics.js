$(function() {

  if ($.isController('exercises') && $('#timeline').isPresent()) {

    var editors = $('.editor');
    var slider = $('#slider>input');
    var submissions = $('#data').data('submissions');
    var files = $('#data').data('files');

    editors.each(function(index, editor) {
      currentEditor = ace.edit(editor);
      currentEditor.$blockScrolling = Infinity;
      currentEditor.setReadOnly(true);
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

  }

});
