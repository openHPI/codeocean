$(document).on('turbo-migration:load', function(event) {

  //Merge all editor components.
  $.extend(
      CodeOceanEditor,
      CodeOceanEditorAJAX,
      CodeOceanEditorEvaluation,
      CodeOceanEditorFlowr,
      CodeOceanEditorSubmissions,
      CodeOceanEditorTurtle,
      CodeOceanEditorWebsocket,
      CodeOceanEditorPrompt,
      CodeOceanEditorRequestForComments
  );

  if ($('#editor').isPresent() && CodeOceanEditor && event.detail.url.includes("/implement")) {
    CodeOceanEditor.initializeEverything();
  }
});

function handleThemeChangeEvent(event) {
  if (CodeOceanEditor) {
    CodeOceanEditor.THEME = event.detail.currentTheme === 'dark' ? 'ace/theme/tomorrow_night' : 'ace/theme/tomorrow';
    document.dispatchEvent(new Event('theme:change:ace'));
  }
}

$(document).on('theme:change', handleThemeChangeEvent);
