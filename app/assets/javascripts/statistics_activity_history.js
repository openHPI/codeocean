$(document).on('turbolinks:load', function() {

  function manageActivityHistory(prefix) {
    var containerId = prefix + '-activity-history';

    if ($('.graph#' + containerId).isPresent()) {

      var chartData;
      var dataset;
      var graph;
      var groups;

      var buildChartGroups = function () {
        return _.map(chartData, function (element) {
          return {
            content: element.name,
            id: element.key,
            visible: true,
            options: {
              interpolation: false,
              yAxisOrientation: element.axis ? element.axis : 'left'
            }
          };
        });
      };

      var initializeChart = function () {
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
          legend: true,
          start: $('#from-date')[0].value || 0,
          end: $('#to-date')[0].value || 0
        });
      };

      var refreshData = function (callback) {
        var params = new URLSearchParams(window.location.search.slice(1));
        var jqxhr = $.ajax(Routes[`statistics_graphs_${prefix}_activity_history_path`](), {
          dataType: 'json',
          data: {from: params.get('from'), to: params.get('to'), interval: params.get('interval')},
          method: 'GET'
        });
        jqxhr.done(function (response) {
          (callback || _.noop)(response);
          updateChartData(response);
        });
      };

      var updateChartData = function (response) {
        _.each(response, function (group) {
          _.each(group.data, function (data) {
            dataset.add({
              group: group.key,
              x: data.key,
              y: data.value
            });
          });
        });
      };

      refreshData(function (data) {
        chartData = data;
        $('#' + containerId).parent().find('.spinner').hide();
        initializeChart();
      });
    }
  }

  if ($.isController('statistics')) {
    manageActivityHistory('rfc');
    manageActivityHistory('user');
  }
});
