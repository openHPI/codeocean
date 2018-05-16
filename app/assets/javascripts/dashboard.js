$(function() {
  var CHART_START = window.vis ? vis.moment().add(-1, 'minute') : undefined;
  var DEFAULT_REFRESH_INTERVAL = 5000;

  var refreshInterval;

  var dataset;
  var graph;
  var groups;

  var buildChartGroups = function() {
    return _.map($('tbody tr[data-id]'), function(element) {
      return {
        content: $('td.name', element).text(),
        id: $(element).data('id'),
        visible: false
      };
    });
  };

  var initializeChart = function() {
    dataset = new vis.DataSet();
    groups = new vis.DataSet(buildChartGroups());
    graph = new vis.Graph2d(document.getElementById('graph'), dataset, groups, {
      dataAxis: {
        left: {
          range: {min: 0}
        },
        showMinorLabels: false
      },
      drawPoints: {
        style: 'circle'
      },
      end: vis.moment(),
      legend: true,
      shaded: true,
      start: CHART_START
    });
  };

  var refreshChart = function() {
    var now = vis.moment();
    var window = graph.getWindow();
    var interval = window.end - window.start;
    graph.setWindow(now - interval, now);
  };

  var refreshData = function(callback) {
    if (! $.isController('dashboard')) {
      clearInterval(refreshInterval);
    } else {
      var jqxhr = $.ajax({
        dataType: 'json',
        method: 'GET'
      });
      jqxhr.done(function(response) {
        (callback || _.noop)(response);
        setGroupVisibility(response);
        updateChartData(response);
        updateTable(response);
        requestAnimationFrame(refreshChart);
      });
    }
  };

  var setGroupVisibility = function(response) {
    _.each(response.docker, function(data) {
      groups.update({
        id: data.id,
        visible: data.pool_size > 0
      });
    });
  };

  var updateChartData = function(response) {
    _.each(response.docker, function(data) {
      dataset.add({
        group: data.id,
        x: vis.moment(),
        y: data.quantity
      });
    });
  };

  var updateProgressBar = function(progress_bar, data) {
    var percentage = Math.min(Math.round(data.quantity / data.pool_size * 100), 100);
    progress_bar.attr({
      'aria-valuemax': data.pool_size,
      'aria-valuenow': data.quantity,
      style: 'width: ' + percentage + '%'
    });
    progress_bar.html(data.quantity);
  };

  var updateTable = function(response) {
    _.each(response.docker, function(data) {
      var row = $('tbody tr[data-id=' + data.id + ']');
      $('.pool-size', row).html(data.pool_size);
      var progress_bar = $('.quantity .progress .progress-bar', row);
      updateProgressBar(progress_bar, data);
    });
  };

  if ($.isController('dashboard') && $('#graph').isPresent()) {
    initializeChart();
    refreshData();
    var refresh_interval = location.search.match(/interval=(\d+)/) ? parseInt(RegExp.$1) : DEFAULT_REFRESH_INTERVAL;
    refreshInterval = setInterval(refreshData, refresh_interval);
  }

});
