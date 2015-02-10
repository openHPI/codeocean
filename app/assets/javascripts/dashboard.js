$(function() {
  var REFRESH_INTERVAL = 5000;

  var refreshData = function() {
    var jqxhr = $.ajax({
      dataType: 'json',
      method: 'GET'
    });
    jqxhr.done(updateView);
  };

  var updateProgressBar = function(progress_bar, data) {
    var percentage = Math.round(data.quantity / data.pool_size * 100);
    progress_bar.attr({
      'aria-valuemax': data.pool_size,
      'aria-valuenow': data.quantity,
      style: 'width: ' + percentage + '%'
    });
    progress_bar.html(data.quantity);
  };

  var updateView = function(response) {
    _.each(response.docker, function(data) {
      var row = $('tbody tr[data-id=' + data.id + ']');
      $('.pool-size', row).html(data.pool_size);
      var progress_bar = $('.quantity .progress .progress-bar', row);
      updateProgressBar(progress_bar, data);
    });
  };

  if ($.isController('dashboard')) {
    refreshData();
    setInterval(refreshData, REFRESH_INTERVAL);
  }
});
