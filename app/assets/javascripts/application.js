// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require turbolinks
//= require rails-timeago
//= require locales/jquery.timeago.de.js
//
// lib/assets
//= require flash
//= require color_mode_picker
//
// app/assets
// --> Include some assets first, as they are used by other assets.
// --> Hence, the order specified here is important.
//
// 1. Some common base functions and monkey patches
//= require base
// 2. Programming groups are required by "channels/synchronized_editor_channel.js"
//= require programming_groups
// 3. The turtle library is required by "editor/turtle.js"
//= require turtle
// 4. Some channels are required by "editor/editor.js.erb"
//= require_tree ./channels
// 5. Require the editor components, as needed by "./editor.js" and "./community_solution.js"
//= require_tree ./editor
//
// All remaining assets are loaded in alphabetical order
//= require_tree .
