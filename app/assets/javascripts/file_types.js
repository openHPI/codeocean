$(document).on('turbolinks:load', function() {
  if ($.isController('file_types')) {
    const select_tag = $('#file_type_editor_mode');

    // The select_tag is only present when the form for new / edited file types is shown.
    if (select_tag) {
      // Populate the select_tag with the available modes
      const ace_modelist = ace.require('ace/ext/modelist');
      ace_modelist.modes.map((mode) => {
        const option = new Option(mode.caption, mode.mode);
        select_tag.append(option);
      })

      // Pre-select the previous element if set
      select_tag.val(select_tag.data('selected'));

      // Notify select2 about the change
      select_tag.trigger('change');
    }
  }
});
