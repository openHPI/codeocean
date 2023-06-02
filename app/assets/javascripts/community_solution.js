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
        $('#submit').one('click', CodeOceanEditorSubmissions.submitCode.bind(CodeOceanEditor));
        $('#accept').one('click', CodeOceanEditorSubmissions.submitCode.bind(CodeOceanEditor));
    }

});
