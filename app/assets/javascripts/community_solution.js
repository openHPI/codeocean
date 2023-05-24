$(document).on('turbolinks:load', function() {

    if ($.isController('community_solutions') && $('#community-solution-editor').isPresent()) {
        CodeOceanEditor.sendEvents = false;
        CodeOceanEditor.editors = [];
        CodeOceanEditor.initializeDescriptionToggle();
        CodeOceanEditor.configureEditors();
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

function submitCode(event) {
    const button = $(event.target) || $('#submit');
    this.startSentryTransaction(button);
    this.teardownEventHandlers();
    this.createSubmission(button, null, function (response) {
        if (response.redirect) {
            this.autosaveIfChanged();
            this.stopCode(event);
            this.editors = [];
            Turbolinks.clearCache();
            Turbolinks.visit(response.redirect);
        } else if (response.status === 'container_depleted') {
            this.showContainerDepletedMessage();
        } else if (response.message) {
            $.flash.danger({
                text: response.message
            });
        }
        this.initializeEventHandlers();
    })
}
