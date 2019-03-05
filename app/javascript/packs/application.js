/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.slim

// JS
import 'jquery'
import 'bootstrap/dist/js/bootstrap.bundle.min';
import 'chosen-js/chosen.jquery';
import 'jstree';
import 'underscore';
import 'd3'
window._ = _; // Publish underscore's `_` in global namespace
window.d3 = d3; // Publish d3 in global namespace

// CSS
import 'chosen-js/chosen.css';
import 'jstree/dist/themes/default/style.min.css';

// custom jquery-ui library for minimal mouse interaction support
import 'jquery-ui/ui/widget'
import 'jquery-ui/ui/data'
import 'jquery-ui/ui/disable-selection'
import 'jquery-ui/ui/scroll-parent'
import 'jquery-ui/ui/widgets/draggable'
import 'jquery-ui/ui/widgets/droppable'
import 'jquery-ui/ui/widgets/resizable'
import 'jquery-ui/ui/widgets/selectable'
import 'jquery-ui/ui/widgets/sortable'
import 'jquery-ui/themes/base/draggable.css'
import 'jquery-ui/themes/base/core.css'
import 'jquery-ui/themes/base/resizable.css'
import 'jquery-ui/themes/base/selectable.css'
import 'jquery-ui/themes/base/sortable.css'
