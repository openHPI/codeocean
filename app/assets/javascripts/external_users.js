$(function() {
  var grid = $('#tag-grid');

  if ($.isController('external_users') && grid.isPresent()) {
    var spinner = $('#loading');
    var noElements = $('#no-elements');

    var buildTagContainer = function(tag) {
      return '\
        <a href="' + location.href +'/statistics?tag=' + tag.id + '">\
          <div class="tag">\
            <div class="name">' + tag.key + '</div>\
            <div class="progress">\
              <div class="progress-bar" role="progressbar" style="width:' + tag.value + '%">' + tag.value + '%</div>\
            </div>\
          </div>\
        </a>';
    };

    var jqxhr = $.ajax(window.location.href + '/tag_statistics', {
      dataType: 'json',
      method: 'GET'
    });
    jqxhr.done(function(response) {
      spinner.hide();
      if (response.length === 0) {
        noElements.show();
      } else {
        var elements = response.map(buildTagContainer);
        grid.append(elements);
      }
    });
  }
});
