$( document ).on('turbolinks:load', function() {
  var DURATION = 10000;
  var SEVERITIES = ['danger', 'info', 'success', 'warning'];

  var buildFlash = function(options) {
    if (options.text) {
      var container = options.container;
      var html = (options.icon ? '<i class="' + options.icon.join(' ') + '"></i>' : '') + options.text;
      container.html(html);
      showFlashes(options.showPermanent);
    }
  };

  var generateMethods = function() {
    $.flash = {};
    $.each(SEVERITIES, function(index, severity) {
      $.flash[severity] = function(options) {
        buildFlash($.extend(options, {
          container: $('#flash-' + severity)
        }));
      };
    });
  };

  var showFlashes = function(showPermanent) {
    $('.flash').each(function() {
      var container = $(this);
      var message = container.find('p');
      var button = container.find('span.fa-xmark');

      var hide = function() {
        container.slideUp(function () {
          message.html('');
        });
      };

      if (message.html() !== '') {
        container.slideDown();
        if (showPermanent !== true)
          container.animation = setTimeout(hide, DURATION);
      }

      // This will be fired by Bootstrap automatically
      container.on('close.bs.alert', function (e) {
        // Did the user click on the on the button to close?
        if (e.target instanceof Element || e.target instanceof HTMLElement) {
          clearTimeout(container.animation);
          hide();
        }
        // We need to stop event propagation here. Otherwise, Bootstrap would remove the DOM element
        e.preventDefault();
      })
    });
  };

  generateMethods();
  $(showFlashes);
});
