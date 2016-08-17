$(function() {
    var ACE_FILES_PATH = '/assets/ace/';
    var THEME = 'ace/theme/textmate';

    var configureEditors = function() {
        _.each(['modePath', 'themePath', 'workerPath'], function(attribute) {
            ace.config.set(attribute, ACE_FILES_PATH);
        });
    };

    var initializeEditors = function() {
        $('.editor').each(function(index, element) {
            var editor = ace.edit(element);

            var document = editor.getSession().getDocument();
            // insert pre-existing code into editor. we have to use insertLines, otherwise the deltas are not properly added
            var file_id = $(element).data('file-id');
            var content = $('.editor-content[data-file-id=' + file_id + ']');

            document.insertLines(0, content.text().split(/\n/));
            // remove last (empty) that is there by default line
            document.removeLines(document.getLength() - 1, document.getLength() - 1);
            editor.setReadOnly($(element).data('read-only') !== undefined);
            editor.setShowPrintMargin(false);
            editor.setTheme(THEME);
            editor.commands.bindKey("ctrl+alt+0", null);
            var session = editor.getSession();
            session.setMode($(element).data('mode'));
            session.setTabSize($(element).data('indent-size'));
            session.setUseSoftTabs(true);
            session.setUseWrapMode(true);

            var file_id = $(element).data('id');
        }
    )};

    if ($('#editor-edit').isPresent()) {
            configureEditors();
            initializeEditors();
            $('.frame').show();
    }
});

