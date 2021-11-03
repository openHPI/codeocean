$(document).on('turbolinks:load', function() {
  if ($.isController('statistics') && $('.graph#user-activity').isPresent()) {

    function manageGraph(containerId, url, refreshAfter) {
      var CHART_START = window.vis ? vis.moment().add(-1, 'minute') : undefined;
      var DEFAULT_REFRESH_INTERVAL = refreshAfter * 1000 || 10000;

      var refreshInterval;

      var initialData;
      var dataset;
      var graph;
      var groups;

      var buildChartGroups = function() {
        return _.map(initialData, function(element) {
          return {
            content: element.name + (element.unit ? ' [' + element.unit + ']' : ''),
            id: element.key,
            visible: false,
            options: {
              yAxisOrientation: element.axis ? element.axis : 'left'
            }
          };
        });
      };

      var initializeChart = function() {
        dataset = new vis.DataSet();
        groups = new vis.DataSet(buildChartGroups());
        graph = new vis.Graph2d(document.getElementById(containerId), dataset, groups, {
          dataAxis: {
            left: {
              range: {min: 0}
            },
            right: {
              range: {min: 0}
            },
            showMinorLabels: true,
            alignZeros: true
          },
          drawPoints: {
            style: 'circle'
          },
          end: vis.moment(),
          legend: true,
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
        if (! ($.isController('statistics') && $('#' + containerId).isPresent())) {
          clearInterval(refreshInterval);
        } else {
          var jqxhr = $.ajax(url, {
            dataType: 'json',
            method: 'GET'
          });
          jqxhr.done(function(response) {
            (callback || _.noop)(response);
            setGroupVisibility(response);
            updateChartData(response);
            requestAnimationFrame(refreshChart);
          });
        }
      };

      var setGroupVisibility = function(response) {
        _.each(response, function(data) {
          groups.update({
            id: data.key,
            visible: true
          });
        });
      };

      var updateChartData = function(response) {
        _.each(response, function(data) {
          dataset.add({
            group: data.key,
            x: vis.moment(),
            y: data.data
          });
        });
      };

      refreshData(function (data) {
        initialData = data;
        $('#' + containerId).parent().find('.spinner').hide();
        initializeChart();

        var refresh_interval = location.search.match(/interval=(\d+)/) ? parseInt(RegExp.$1) : DEFAULT_REFRESH_INTERVAL;
        refreshInterval = setInterval(refreshData, refresh_interval);
      });
    }

    manageGraph('user-activity', Routes.statistics_graphs_user_activity_path(), 10);
    manageGraph('rfc-activity', Routes.statistics_graphs_rfc_activity_path(), 30);
  }
});
