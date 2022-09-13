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
    scrollTop: $(document.querySelector(selector)).offset().top - $(this).offset().top + $(this).scrollTop()
  }, ANIMATION_DURATION);
};

// Disable the use of web workers for JStree due to JS error
// See https://github.com/vakata/jstree/issues/1717 for details
$.jstree.defaults.core.worker = false;

// Update all CSRF tokens on the page to reduce InvalidAuthenticityToken errors
// See https://github.com/rails/jquery-ujs/issues/456 for details
$(document).on('turbolinks:load', function(){
    $.rails.refreshCSRFTokens();
    $('.reloadCurrentPage').on('click', function() {
        window.location.reload();
    });
});
