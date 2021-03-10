CodeOceanEditorAJAX = {
  ajax: function(options) {
    return $.ajax(_.extend({
      dataType: 'json',
      method: 'POST',
    }, options));
  },

  ajaxError: function(response) {
    var message = ((response || {}).responseJSON || {}).message || '';

    $.flash.danger({
      text: message.length > 0 ? message : $('#flash').data('message-failure')
    });
    Sentry.setContext("error",{
        cookie: document.cookie,
        response: response.responseText,
        csrf: $('meta[name="csrf-token"]').attr("content")
    });
    Sentry.captureException(JSON.stringify(response));
  }
};