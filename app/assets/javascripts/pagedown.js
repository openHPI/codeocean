(function() {
    var ACE_FILES_PATH = '/assets/ace/';

    window.PagedownEditor = function(selector) {
        var converter = Markdown.getSanitizingConverter();
        var editor    = new Markdown.Editor( converter );

        editor.run();
    };
})();