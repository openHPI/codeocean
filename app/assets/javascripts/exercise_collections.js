$(document).on('turbo-migration:load', function() {
  if ($.isController('exercise_collections')) {
    var dataElement = $('#data');
    var exerciseList = $('#exercise-list');

    if (dataElement.isPresent()) {
      var data = dataElement.data('working-times');
      var averageWorkingTimeValue = parseFloat(dataElement.data('average-working-time'));

      var margin = {top: 30, right: 40, bottom: 30, left: 50},
        width = 720 - margin.left - margin.right,
        height = 500 - margin.top - margin.bottom;

      var x = d3.scaleBand().range([0, width]);
      var y = d3.scaleLinear().range([height, 0]);

      var xAxis = d3.axisBottom(x);
      var yAxisLeft = d3.axisLeft(y);

      var tooltip = d3.select("#graph").append("div").attr("class", "exercise-id-tooltip");

      var averageWorkingTime = d3.line()
        .x(function (d) {
          return x(d.index) + x.bandwidth() / 2;
        })
        .y(function () {
          return y(averageWorkingTimeValue);
        });

      var minWorkingTime = d3.line()
        .x(function (d) {
          return x(d.index) + x.bandwidth() / 2;
        })
        .y(function () {
          return y(0.1 * averageWorkingTimeValue);
        });

      var maxWorkingTime = d3.line()
        .x(function (d) {
          return x(d.index) + x.bandwidth() / 2;
        })
        .y(function () {
          return y(2 * averageWorkingTimeValue);
        });

      var svg = d3.select('#graph')
        .append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform",
          "translate(" + margin.left + "," + margin.top + ")");

      // Get the data
      data = Object.keys(data).map(function (key) {
        return {
          index: parseInt(key),
          exercise_id: parseInt(data[key]['exercise_id']),
          exercise_title: data[key]['exercise_title'],
          working_time: parseFloat(data[key]['working_time'])
        };
      });

      // Scale the range of the data
      x.domain(data.map(function (d) {
        return d.index;
      }));
      y.domain([0, d3.max(data, function (d) {
        return d.working_time;
      })]);

      // Add the X Axis
      svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis);

      // Add the Y Axis
      svg.append("g")
        .attr("class", "y axis")
        .style("fill", "steelblue")
        .call(yAxisLeft);

      // Draw the bars
      svg.selectAll("bar")
        .data(data)
        .enter()
        .append("rect")
        .attr("class", "value-bar")
        .on("mousemove", function (event, d) {
          tooltip
            .style("left", event.pageX - 50 + "px")
            .style("top", event.pageY + 50 + "px")
            .style("display", "inline-block")
            .html(`${I18n.t('activerecord.models.exercise.one')} ID: ${d.exercise_id}<br>` +
              `${I18n.t('activerecord.attributes.exercise.title')}: ${d.exercise_title}<br>` +
              `${I18n.t('exercises.statistics.average_worktime')}: ${d.working_time}s`);
        })
        .on("mouseout", function () {
          tooltip.style("display", "none");
        })
        .on("click", function (_event, d) {
          Turbo.visit(Routes.statistics_exercise_path(d.exercise_id));
        })
        .attr("x", function (d) {
          return x(d.index);
        })
        .attr("width", x.bandwidth())
        .attr("y", function (d) {
          return y(d.working_time);
        })
        .attr("height", function (d) {
          return height - y(d.working_time);
        });

      // Add the average working time path
      svg.append("path")
        .datum(data)
        .attr("class", "line average-working-time")
        .attr("d", averageWorkingTime);

      // Add the anomaly paths (min/max average exercise working time)
      svg.append("path")
        .datum(data)
        .attr("class", "line minimum-working-time")
        .attr("d", minWorkingTime);
      svg.append("path")
        .datum(data)
        .attr("class", "line maximum-working-time")
        .attr("d", maxWorkingTime);
    } else if (exerciseList.isPresent()) {
      var exerciseSelect = $('#exercise-select');
      var list = $("#sortable");

      var updateExerciseList = function () {
        // remove all options from the hidden select and add all selected exercises in the new order
        exerciseSelect.find('option').remove();
        var exerciseIdsInSortedOrder = list.sortable('toArray', {attribute: 'data-id'});
        for (var i = 0; i < exerciseIdsInSortedOrder.length; i += 1) {
          exerciseSelect.append('<option value="' + exerciseIdsInSortedOrder[i] + '" selected></option>')
        }
      }

      list.sortable({
        items: 'tr',
        update: updateExerciseList
      });
      list.disableSelection();

      var addExercisesForm = $('#exercise-selection');
      var addExercisesButton = $('#add-exercises');
      var removeExerciseButtons = $('.remove-exercise');
      var sortButton = $('#sort-button');

      var collectContainedExercises = function () {
        return exerciseList.find('tbody > tr').toArray().map(function (item) {return $(item).data('id')});
      }

      var sortExercises = function() {
        var listitems = $('tr', list);
        listitems.sort(function (a, b) {
          return ($(a).find('td:nth-child(2)').text().toUpperCase() > $(b).find('td:nth-child(2)').text().toUpperCase()) ? 1 : -1;
        });
        list.append(listitems);
        list.sortable('refresh');
        updateExerciseList();
      }

      var addExercise = function (id, title) {
        var exercise = {id: _.escape(id), title: _.escape(title)}
        var collectionExercises = collectContainedExercises();
        if (collectionExercises.indexOf(exercise.id) === -1) {
          // only add exercises that are not already contained in the collection
          var template = '<tr data-id="' + exercise.id + '">' +
            '<td><span class="fa-solid fa-bars"></span></td>' +
            '<td>' + exercise.title + '</td>' +
            `<td><a href="${Routes.exercise_path(exercise.id)}">${I18n.t('shared.show')}</td>` +
            `<td><a class="remove-exercise" href="#">${I18n.t('shared.destroy')}</td></tr>`;
          exerciseList.find('tbody').append(template);
          $('#exercise-list').find('option[value="' + exercise.id + '"]').prop('selected', true);
        }
      }

      addExercisesButton.on('click', function (e) {
        e.preventDefault();
        const selectedExercises = addExercisesForm.find('select')[0].selectedOptions;
        for (var i = 0; i < selectedExercises.length; i++) {
          addExercise(selectedExercises[i].value, selectedExercises[i].label);
        }
        bootstrap.Modal.getInstance($('#add-exercise-modal'))?.hide();
        updateExerciseList();
        addExercisesForm.find('select').val('').trigger("chosen:updated");
      });

      removeExerciseButtons.on('click', function (e) {
        e.preventDefault();

        var row = $(this).parent().parent();
        var exerciseId = row.data('id');
        $('#exercise-list').find('option[value="' + exerciseId + '"]').prop('selected', false);
        row.remove();
        updateExerciseList();
      });

      sortButton.on('click', function (e) {
        e.preventDefault();
        sortExercises();
      });
    }
  }
});
