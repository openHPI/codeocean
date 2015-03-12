$(function() {
  var CHOSEN_OPTIONS = {
    allow_single_deselect: true,
    disable_search_threshold: 5,
    search_contains: true
  };

  $('form').on('click', '.toggle-input', function(event) {
    event.preventDefault();

    if (!$(this).hasClass('disabled')) {
      var parent = $(this).parents('.form-group');
      var original_input = parent.find('.original-input');
      var alternative_input = parent.find('.alternative-input');

      if (alternative_input.attr('disabled')) {
        $(this).text($(this).data('text-toggled'));
        original_input.attr('disabled', true).hide();
        alternative_input.attr('disabled', false).show();
      } else {
        $(this).text($(this).data('text-initial'));
        alternative_input.attr('disabled', true).hide();
        original_input.attr('disabled', false).show();
      }
    }
  });

  window.CodeOcean.CHOSEN_OPTIONS = CHOSEN_OPTIONS;
  $('select:visible').chosen(CHOSEN_OPTIONS);
});
