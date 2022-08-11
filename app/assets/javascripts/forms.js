$(document).on('turbolinks:load', function() {
  var CHOSEN_OPTIONS = {
    allow_single_deselect: true,
    disable_search_threshold: 5,
    search_contains: true
  };

  $('form').on('click', '.toggle-input', function(event) {
    event.preventDefault();

    if (!$(this).hasClass('disabled')) {
      var parent = $(this).parents('.mb-3');
      var original_input = parent.find('.original-input');
      var alternative_input = parent.find('.alternative-input');

      if (alternative_input.attr('disabled')) {
        $(this).text($(event.target).first().data('text_toggled'));
        original_input.attr('disabled', true).hide();
        alternative_input.attr('disabled', false).show();
      } else {
        $(this).text($(event.target).first().data('text_initial'));
        alternative_input.attr('disabled', true).hide();
        original_input.attr('disabled', false).show();
      }
    }
  });

  window.CodeOcean.CHOSEN_OPTIONS = CHOSEN_OPTIONS;
  chosen_inputs = $('select').filter(function(){
    return !$(this).parents('ul').is('#dummies');
  });

  // enable chosen hook when editing an exercise to update ace code highlighting
  if ($.isController('exercises') && $('.edit_exercise, .new_exercise').isPresent() ||
      $.isController('tips') && $('.edit_tip, .new_tip').isPresent()  ) {
      chosen_inputs.filter(function(){
          return $(this).attr('id').includes('file_type_id');
      }).on('change chosen:ready', function(event, parameter) {
          // Set ACE editor mode (for code highlighting) on change of file type and after initialization
          editorInstance = $(event.target).closest('.card-body').find('.editor')[0];
          if (editorInstance === undefined) {
              editorInstance = $(event.target).closest('.container').find('.editor')[0];
          }
          selectedFileType = event.target.value;
          CodeOceanEditor.updateEditorModeToFileTypeID(editorInstance, selectedFileType);
      })
  }

  chosen_inputs.chosen(CHOSEN_OPTIONS);
});

// Remove some elements before going back to an older site. Otherwise, they might not work.
$(document).on('turbolinks:before-cache', function() {
    $('.chosen-container').remove();
    $('#wmd-button-row-description').remove();
});
