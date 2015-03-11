Array.prototype.includes = function(element) {
  return this.indexOf(element) !== -1;
};

window.CodeOcean = {
  refresh: function() {
    Turbolinks.visit(window.location.pathname);
  }
};

$(function() {
  var ANIMATION_DURATION = 500;

  $.isController = function(name) {
    return $('.container[data-controller="' + name + '"]').isPresent();
  };

  $.fn.isPresent = function() {
    return this.length > 0;
  };

  $.fn.scrollTo = function(selector) {
    $(this).animate({
      scrollTop: $(selector).offset().top - $(this).offset().top + $(this).scrollTop()
    }, ANIMATION_DURATION);
  };
});
