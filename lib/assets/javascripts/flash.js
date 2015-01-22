(function() {
  var DURATION = 10000;
  var SEVERITIES = ['danger', 'info', 'success', 'warning'];

  var buildFlash = function(options) {
    if (options.text) {
      var container = options.container;
      var html = '';
      if (options.icon) {
        html += '<i class="' + options.icon.join(' ') + '">&nbsp;';
      }
      html += options.text;
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
      if ($(this).html() !== '') {
        $(this).slideDown().delay(DURATION).slideUp(function() {
          $(this).html('');
        });
      }
    });
  };

  generateMethods();
  $(showFlashes);
})();
