$(function() {
  var ACE_FILES_PATH = '/assets/ace/';
  var TAB_KEY_CODE = 9;

  var addFileForm = function(event) {
    event.preventDefault();
    var element = $('#dummies').children().first().clone();
    var html = $('<div>').append(element).html().replace(/index/g, new Date().getTime());
    $('#files').append(html);
    $('#files select').chosen({
      disable_search_threshold: 5,
      search_contains: true
    });
    $('body, html').scrollTo('#add-file');
  };

  var enableInlineFileCreation = function() {
    $('#add-file').on('click', addFileForm);
    $('form.edit_exercise, form.new_exercise').on('submit', function() {
      $('#dummies').html('');
    });
  };

  var highlightCode = function() {
    $('pre code').each(function(index, element) {
      hljs.highlightBlock(element);
    });
  };

  var inferFileAttributes = function() {
    $(document).on('change', 'input[type="file"]', function(event) {
      var filename = $(this).val().split(/\\|\//g).pop();
      var parent = $(this).parents('li');
      parent.find('input[type="text"]').first().val(filename.split('.')[0]);
    });
  };

  var insertTabAtCursor = function(textarea) {
    var selection_start = textarea.get(0).selectionStart;
    var selection_end = textarea.get(0).selectionEnd;
    textarea.val(textarea.val().substring(0, selection_start) + "\t" + textarea.val().substring(selection_end));
    textarea.get(0).selectionStart = selection_start + 1;
    textarea.get(0).selectionEnd = selection_start + 1;
  };

  var observeFileRoleChanges = function() {
    $(document).on('change', 'select[name$="[role]"]', function() {
      var is_test_file = $(this).val() === 'teacher_defined_test';
      var parent = $(this).parents('.panel');
      parent.find('[name$="[feedback_message]"]').attr('disabled', !is_test_file);
      parent.find('[name$="[weight]"]').attr('disabled', !is_test_file);
    });
  };

  var overrideTextareaTabBehavior = function() {
    $('.form-group textarea').on('keydown', function(event) {
      if (event.which === TAB_KEY_CODE) {
        event.preventDefault();
        insertTabAtCursor($(this));
      }
    });
  };

  var toggleCodeHeight = function() {
    $('code').on('click', function() {
      $(this).css({
        'max-height': 'initial'
      })
    });
  };

  if ($.isController('exercises')) {
    if ($('.edit_exercise, .new_exercise').isPresent()) {
      new MarkdownEditor('#exercise_instructions');
      enableInlineFileCreation();
      inferFileAttributes();
      observeFileRoleChanges();
      overrideTextareaTabBehavior();
    }
    toggleCodeHeight();
    if (window.hljs) {
      highlightCode();
    }
  }
});
