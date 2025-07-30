import CodeOceanEditorAJAX from './ajax';
import CodeOceanEditor from './editor';
import CodeOceanEditorEvaluation from './evaluation';
import CodeOceanEditorWebsocket from './execution';
import { CodeOceanEditorFlowr, CodeOceanEditorRequestForComments }  from './participantsupport';
import CodeOceanEditorPrompt from './prompt';
import CodeOceanEditorSubmissions from './submissions';
import CodeOceanEditorTurtle from './turtle';

// TODO: Import explicitly in Part 3 of the asset migration.
window.CodeOceanEditorAJAX = CodeOceanEditorAJAX;
window.CodeOceanEditor = CodeOceanEditor;
window.CodeOceanEditorEvaluation = CodeOceanEditorEvaluation;
window.CodeOceanEditorWebsocket = CodeOceanEditorWebsocket;
window.CodeOceanEditorFlowr = CodeOceanEditorFlowr;
window.CodeOceanEditorPrompt = CodeOceanEditorPrompt;
window.CodeOceanEditorRequestForComments = CodeOceanEditorRequestForComments;
window.CodeOceanEditorSubmissions = CodeOceanEditorSubmissions;
window.CodeOceanEditorTurtle = CodeOceanEditorTurtle;
