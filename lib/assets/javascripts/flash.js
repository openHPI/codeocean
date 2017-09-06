(function() {
  var DURATION = 10000;
  var SEVERITIES = ['danger', 'info', 'success', 'warning'];

  var buildFlash = function(options) {
    if (options.text) {
      var container = options.container;
      var html = (options.icon ? '<i class="' + options.icon.join(' ') + '"></i>' : '') + options.text;
      container.html(html);
      showFlashes();
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

  var showFlashes = function() {
    $('.flash').each(function() {
      var container = $(this);
      var message = container.find('p');
      var button = container.find('span.fa-times');

      var hide = function() {
        container.slideUp(function () {
          message.html('');
        });
      };

      if (message.html() !== '') {
        container.slideDown();
        container.animation = setTimeout(hide, DURATION);
      }

      button.on('click', function () {
        clearTimeout(container.animation);
        hide();
      });
    });
  };

  generateMethods();
  $(showFlashes);
})();
