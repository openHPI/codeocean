$(document).on('turbo-migration:load', function() {

    if ($.isController('community_solutions') && $('#community-solution-editor').isPresent()) {
        CodeOceanEditor.sendEvents = false;
        CodeOceanEditor.editors = [];
        CodeOceanEditor.initializeDescriptionToggle();
        CodeOceanEditor.initializeEditors();
        CodeOceanEditor.initializeEditors(true);
        CodeOceanEditor.initializeFileTree();
        CodeOceanEditor.initializeFileTree(true);
        CodeOceanEditor.showFirstFile();
        CodeOceanEditor.showFirstFile(true);
        CodeOceanEditor.resizeAceEditors();
        CodeOceanEditor.resizeAceEditors(true);

        $.extend(
            CodeOceanEditor,
            CodeOceanEditorAJAX,
            CodeOceanEditorSubmissions
        )

        $(document).on('theme:change:ace', CodeOceanEditor.handleAceThemeChangeEvent.bind(CodeOceanEditor));
        $('#submit').one('click', submitCode.bind(CodeOceanEditor));
        $('#accept').one('click', submitCode.bind(CodeOceanEditor));
    }
});

$(document).one('turbo-migration:load', function() {
    if ($.isController('community_solutions') && $('#community-solution-editor').isPresent()) {
        $(document).one('turbo:visit', unloadEditorHandler);
        $(window).one('beforeunload', unloadEditorHandler);
    }
});

function unloadEditorHandler() {
    CodeOceanEditor.autosaveIfChanged();
    CodeOceanEditor.unloadEditor();
}

function submitCode(event) {
    const button = $(event.target) || $('#submit');
    this.newSentryTransaction(button, async () => {
        const submission = await this.createSubmission(button, null).catch((response) => {
            this.ajaxError(response);
            button.one('click', this.submitCode.bind(this));
        });
        if (!submission) return;
        if (!submission.redirect) return;

        unloadEditorHandler();
        Turbo.visit(submission.redirect);
    });
}
