(function() 
{
  var converter = Markdown.getSanitizingConverter();
  var editor = new Markdown.Editor(converter);
  editor.run();
/*  
	window.MarkdownEditor = function(selector) 
	{
    ace.config.set('modePath', ACE_FILES_PATH);
    var editor = ace.edit($(selector).next()[0]);
    editor.on('change', function(){ $(selector).val(editor.getValue()); });
    editor.setShowPrintMargin(false);
    var session = editor.getSession();
    session.setMode('markdown');
    session.setUseWrapMode(true);
    session.setValue($(selector).val());
 };
 */
})();
