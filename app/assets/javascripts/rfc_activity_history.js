$(document).ready(function () {
  var containerId = 'rfc-activity-history';

  if ($.isController('statistics') && $('.graph#' + containerId).isPresent()) {

    var chartData;
    var dataset;
    var graph;
    var groups;

    var buildChartGroups = function() {
      return _.map(chartData, function(element) {
        return {
          content: element.name,
          id: element.key,
          visible: true,
          options: {
            interpolation: false
          }
        };
      });
    };

    var initializeChart = function() {
      dataset = new vis.DataSet();
      groups = new vis.DataSet(buildChartGroups());
      graph = new vis.Graph2d(document.getElementById(containerId), dataset, groups, {
        dataAxis: {
          customRange: {
            left: {
              min: 0
            }
          },
          showMinorLabels: true
        },
        drawPoints: {
          style: 'circle'
        },
        legend: true,
        start: $('#from-date')[0].value,
        end: $('#to-date')[0].value
      });
    };

    var refreshData = function(callback) {
      var params = new URLSearchParams(window.location.search.slice(1));
      var jqxhr = $.ajax('rfc-activity-history.json', {
        dataType: 'json',
        data: {from: params.get('from'), to: params.get('to'), interval: params.get('interval')},
        method: 'GET'
      });
      jqxhr.done(function(response) {
        (callback || _.noop)(response);
        updateChartData(response);
      });
    };

    var updateChartData = function(response) {
      _.each(response, function(group) {
        _.each(group.data, function(data) {
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
});
