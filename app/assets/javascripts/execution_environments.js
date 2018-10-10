$(document).on('turbolinks:load', function() {
  if ($.isController('execution_environments')) {
    if ($('.edit_execution_environment, .new_execution_environment').isPresent()) {
      new MarkdownEditor('#execution_environment_help');
    }
  }
});
