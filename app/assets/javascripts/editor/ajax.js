CodeOceanEditorAJAX = {
  ajax: function(options) {
    return $.ajax(_.extend({
      dataType: 'json',
      method: 'POST',
    }, options));
  },

  ajaxError: function(response) {
    const responseJSON = ((response || {}).responseJSON || {});
    const message = responseJSON.message || responseJSON.error || '';

    $.flash.danger({
      text: message.length > 0 ? message : $('#flash').data('message-failure'),
      showPermanent: response.status === 422,
    });
  }
};
