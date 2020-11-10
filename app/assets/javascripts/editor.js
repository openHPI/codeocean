$(document).on('turbolinks:load', function(event) {

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
      CodeOceanEditorCodePilot,
      CodeOceanEditorRequestForComments
  );

  if ($('#editor').isPresent() && CodeOceanEditor && event.originalEvent.data.url.includes("/implement")) {
    if (CodeOceanEditor.isBrowserSupported()) {
      $('#alert').hide();
      // This call will (amon other things) initializeEditors and load the content except for the last line
      // It must not be called during page navigation. Otherwise, content will be duplicated!
      // Search for insertLines and Turbolinks reload / cache control
      CodeOceanEditor.initializeEverything();
    }
  }
});
