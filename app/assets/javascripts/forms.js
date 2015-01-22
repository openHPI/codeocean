$(function() {
  $('form').on('click', '.toggle-input', function(event) {
    event.preventDefault();
    if (!$(this).hasClass('disabled')) {
      $(this).hide();
      var parent = $(this).parents('.form-group');
      var original_input = parent.find('input:not(disabled), select:not(disabled), textarea:not(disabled), .chosen-container');
      original_input.attr('disabled', true);
      original_input.hide();
      var alternative_input = parent.find('.alternative-input');
      alternative_input.attr('disabled', false);
      alternative_input.show();
      alternative_input.trigger('click');
    }
  });

  $('select:visible').chosen({
    disable_search_threshold: 5,
    search_contains: true
  });
});
