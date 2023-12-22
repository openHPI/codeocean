(function() {
    window.MarkdownEditor = function(selector) {
        _.each(['modePath', 'themePath', 'workerPath'], function (attribute) {
            ace.config.set(attribute, CodeOceanEditor.ACE_FILES_PATH);
        }.bind(this));
        var editor = ace.edit($(selector).next()[0]);
        editor.on('change', function() {
            $(selector).val(editor.getValue());
        });
        editor.setShowPrintMargin(false);
        editor.setTheme(CodeOceanEditor.THEME);
        var session = editor.getSession();
        session.setMode('ace/mode/markdown');
        session.setUseWrapMode(true);
        session.setValue($(selector).val());
    };
})();
