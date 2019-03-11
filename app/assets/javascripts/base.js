Array.prototype.includes = function(element) {
  return this.indexOf(element) !== -1;
};

window.CodeOcean = {
  refresh: function() {
    Turbolinks.visit(window.location.pathname);
  }
};

var ANIMATION_DURATION = 500;

$.isController = function(name) {
  return $('div[data-controller="' + name + '"]').isPresent();
};

$.fn.isPresent = function() {
  return this.length > 0;
};

$.fn.scrollTo = function(selector) {
  $(this).animate({
    scrollTop: $(selector).offset().top - $(this).offset().top + $(this).scrollTop()
  }, ANIMATION_DURATION);
};

$.fn.replaceWithPush = function(a) {
    const $a = $(a);
    this.replaceWith($a);
    return $a;
};

// Disable the use of web workers for JStree due to JS error
// See https://github.com/vakata/jstree/issues/1717 for details
$.jstree.defaults.core.worker = false;
