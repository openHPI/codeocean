$(document).on('turbolinks:load', function() {
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
        id: `execution_environment_${$(element).data('id')}`,
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
        url: Routes.admin_dashboard_path(),
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
        id: `execution_environment_${data.id}`,
        visible: data.prewarmingPoolSize > 0
      });
    });
  };

  var updateChartData = function(response) {
    _.each(response.docker, function(data) {
      dataset.add({
        group: `execution_environment_${data.id}`,
        x: vis.moment(),
        y: data.usedRunners
      });
    });
  };

  var updateProgressBar = function(progress_bar, data) {
    var percentage = Math.min(Math.round(data.idleRunners / data.prewarmingPoolSize * 100), 100);
    progress_bar.attr({
      'aria-valuemax': data.prewarmingPoolSize,
      'aria-valuenow': data.idleRunners,
      style: 'width: ' + percentage + '%'
    });
    progress_bar.html(data.idleRunners);
  };

  var updateTable = function(response) {
    _.each(response.docker, function(data) {
      var row = $('tbody tr[data-id=' + data.id + ']');
      $('.prewarming-pool-size', row).html(data.prewarmingPoolSize);
      $('.used-runners', row).html(`+ ${data.usedRunners}`);
      var progress_bar = $('.idle-runners .progress .progress-bar', row);
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
