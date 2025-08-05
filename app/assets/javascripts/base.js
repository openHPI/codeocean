window.CodeOcean = {
  refresh: function() {
    Turbo.visit(window.location.pathname);
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

$(document).on('turbo-migration:load', function(event) {
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

    // Initialize Sentry
    const sentrySettings = $('meta[name="sentry"]')

    // Workaround for Turbo: We must not re-initialize the Relay object when visiting another page
    if (sentrySettings && sentrySettings.data() && sentrySettings.data()['enabled'] && Sentry.getReplay() === undefined) {
        Sentry.init({
            dsn: sentrySettings.data('dsn'),
            attachStacktrace: true,
            release: sentrySettings.data('release'),
            environment: sentrySettings.data('environment'),
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

    // Enable sorttable again, as it is disabled otherwise by Turbo
    // We use the event details to determine whether an ordinary page load occurred or a Turbo visit
    // In some events (i.e., for a failed form submission), `event.detail.timing` is not set (despite a Turbo "visit").
    if (sorttable && (event.detail?.timing ? Object.keys(event.detail.timing).length > 0 : true)) {
        sorttable.init.done = false;
        sorttable.init();
    }
});
