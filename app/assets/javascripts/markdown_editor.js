$(document).ready(function () {
    var converter = Markdown.getSanitizingConverter();
    var editor    = new Markdown.Editor( converter );

    Markdown.Extra.init( converter );

    editor.run();
});