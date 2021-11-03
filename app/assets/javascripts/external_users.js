$(document).on('turbolinks:load', function() {
  const grid = $('#tag-grid');

  if ($.isController('external_users') && grid.isPresent()) {
    const spinner = $('#loading');
    const user_id = spinner.data('user-id');
    const noElements = $('#no-elements');

    const buildTagContainer = function(tag) {
      return '\
        <a href="' + Routes.statistics_external_user_path(user_id, {tag: tag.id}) + '">\
          <div class="tag">\
            <div class="name">' + tag.key + '</div>\
            <div class="progress">\
              <div class="progress-bar" role="progressbar" style="width:' + tag.value + '%">' + tag.value + '%</div>\
            </div>\
          </div>\
        </a>';
    };

    const jqxhr = $.ajax(Routes.tag_statistics_external_user_path(user_id), {
      dataType: 'json',
      method: 'GET'
    });
    jqxhr.done(function(response) {
      spinner.hide();
      if (response.length === 0) {
        noElements.show();
      } else {
        const elements = response.map(buildTagContainer);
        grid.append(elements);
      }
    });
  }
});
