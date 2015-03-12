$(function() {
  var ACE_FILES_PATH = '/assets/ace/';
  var TAB_KEY_CODE = 9;

  var execution_environments;
  var file_types;

  var addFileForm = function(event) {
    event.preventDefault();
    var element = $('#dummies').children().first().clone();
    var html = $('<div>').append(element).html().replace(/index/g, new Date().getTime());
    $('#files').append(html);
    $('#files li:last select[name*="file_type_id"]').val(getSelectedExecutionEnvironment().file_type_id);
    $('#files li:last select').chosen(window.CodeOcean.CHOSEN_OPTIONS);
    $('body, html').scrollTo('#add-file');
  };

  var discardFile = function(event) {
    event.preventDefault();
    $(this).parents('li').remove();
  };

  var enableInlineFileCreation = function() {
    $('#add-file').on('click', addFileForm);
    $('#files').on('click', 'li .discard-file', discardFile);
    $('form.edit_exercise, form.new_exercise').on('submit', function() {
      $('#dummies').html('');
    });
  };

  var findFileTypeByFileExtension = function(file_extension) {
    return _.find(file_types, function(file_type) {
      return file_type.file_extension === file_extension;
    }) || {};
  };

  var getSelectedExecutionEnvironment = function() {
    return _.find(execution_environments, function(execution_environment) {
      return execution_environment.id === parseInt($('#exercise_execution_environment_id').val());
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
      var file_extension = '.' + filename.split('.')[1];
      var file_type = findFileTypeByFileExtension(file_extension);
      var name = filename.split('.')[0];
      var parent = $(this).parents('li');
      parent.find('input[name*="name"]').val(name);
      parent.find('select[name*="file_type_id"]').val(file_type.id).trigger('chosen:updated');
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
      });
    });
  };

  if ($.isController('exercises')) {
    if ($('.edit_exercise, .new_exercise').isPresent()) {
      execution_environments = $('form').data('execution-environments');
      file_types = $('form').data('file-types');
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
