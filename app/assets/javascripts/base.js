Array.prototype.includes = function(element) {
  return this.indexOf(element) !== -1;
};

window.CodeOcean = {
  refresh: function() {
    Turbolinks.visit(window.location.pathname);
  }
};

const ANIMATION_DURATION = 500;

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

$(document).on('turbolinks:load', function() {
    // Update all CSRF tokens on the page to reduce InvalidAuthenticityToken errors
    // See https://github.com/rails/jquery-ujs/issues/456 for details
    $.rails.refreshCSRFTokens();
    $('.reloadCurrentPage').on('click', function() {
        window.location.reload();
    });

    // Set current user and current contributor
    window.current_user = JSON.parse($('meta[name="current-user"]')?.attr('content') || null);
    window.current_contributor = JSON.parse($('meta[name="current-contributor"]')?.attr('content') || null);

    // Set locale for all JavaScript functions
    const htmlTag = $('html')
    I18n.defaultLocale = htmlTag.data('default-locale');
    I18n.locale = htmlTag.attr('lang');
    jQuery.timeago.settings.lang = I18n.locale;

    // Initialize Sentry
    const sentrySettings = $('meta[name="sentry"]')

    // Workaround for Turbolinks: We must not re-initialize the Relay object when visiting another page
    if (sentrySettings && sentrySettings.data()['enabled'] && !Sentry.Replay.prototype._isInitialized) {
        Sentry.init({
            dsn: sentrySettings.data('dsn'),
            attachStacktrace: true,
            release: sentrySettings.data('release'),
            environment: sentrySettings.data('environment'),
            autoSessionTracking: true,
            tracesSampleRate: 1.0,
            replaysSessionSampleRate: 0.0,
            replaysOnErrorSampleRate: 1.0,
            integrations: window.SentryIntegrations(),
            profilesSampleRate: 1.0,
            initialScope: scope =>{
                if (current_user) {
                    scope.setUser(_.omit(current_user, 'displayname'));
                }
                return scope;
            }
        });
    }

    // Enable all tooltips
    $('[data-bs-toggle="tooltip"]').tooltip();

    // Enable sorttable again, as it is disabled otherwise by Turbolinks
    if (sorttable) {
        sorttable.init.done = false;
        sorttable.init();
    }
});
