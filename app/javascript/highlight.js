/* eslint no-console:0 */

// JS
import hljs from 'highlight.js/lib/common'
import julia from 'highlight.js/lib/languages/julia';
hljs.registerLanguage('julia', julia);
window.hljs = hljs;

// CSS
import 'highlight.js/styles/base16/tomorrow.css'
