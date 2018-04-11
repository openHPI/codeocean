$(document).ready(function () {
  if ($.isController('statistics') && $('.graph#user-activity').isPresent()) {
    var CHART_START = window.vis ? vis.moment().add(-1, 'minute') : undefined;
    var DEFAULT_REFRESH_INTERVAL = 10000;

    var refreshInterval;

    var initialData;
    var dataset;
    var graph;
    var groups;

    var buildChartGroups = function() {
      initialData = initialData.sort(function (a, b) {return a.data - b.data});
      return _.map(initialData, function(element, index) {
        return {
          content: element.name + (element.unit ? ' [' + element.unit + ']' : ''),
          id: element.key,
          visible: false,
          options: {
            yAxisOrientation: index >= initialData.length / 2 ? 'right' : 'left'
          }
        };
      });
    };

    var initializeChart = function() {
      dataset = new vis.DataSet();
      groups = new vis.DataSet(buildChartGroups());
      graph = new vis.Graph2d(document.getElementById('user-activity'), dataset, groups, {
        dataAxis: {
          customRange: {
            left: {
              min: 0
            },
            right: {
              min: 0
            }
          },
          showMinorLabels: true
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
      if (! ($.isController('statistics') && $('#user-activity').isPresent())) {
        clearInterval(refreshInterval);
      } else {
        var jqxhr = $.ajax('graphs/user-activity', {
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
      $('#user-activity').parent().find('.spinner').hide();
      initializeChart();

      var refresh_interval = location.search.match(/interval=(\d+)/) ? parseInt(RegExp.$1) : DEFAULT_REFRESH_INTERVAL;
      refreshInterval = setInterval(refreshData, refresh_interval);
    });
  }
});
