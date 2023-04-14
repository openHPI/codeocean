$(document).on('turbolinks:load', function() {
    // /38/statistics good for testing

  if ($.isController('exercises') && $('.working-time-graphs').isPresent()) {
      var working_times = $('#data').data('working-time');

      function get_minutes (timestamp){
          try{
              hours = timestamp.split(":")[0];
              minutes = timestamp.split(":")[1];
              seconds = timestamp.split(":")[2];

              return parseFloat(hours * 60) + parseInt(minutes);
          } catch (err){
              return 0;
          }

      }

      // GET ALL THE DATA ------------------------------------------------------------------------------
      minutes_array = _.map(working_times, function(item){return get_minutes(item)});
      minutes_array_length = minutes_array.length;

      if (minutes_array_length === 0){
          return;
      }
      maximum_minutes = _.max(minutes_array) + 1; // We need to respect the last minute as well
      const minutes_count = new Array(maximum_minutes).fill(0);

      for (var i = 0; i < minutes_array_length; i++){
          var studentTime = minutes_array[i];

          for (var j = 0; j < studentTime; j++){
              minutes_count[j] += 1;
          }
      }

      function getWidth() {
          if (self.innerWidth) {
              return self.innerWidth;
          }

          if (document.documentElement && document.documentElement.clientWidth) {
              return document.documentElement.clientWidth;
          }

          if (document.body) {
              return document.body.clientWidth;
          }
      }

      // DRAW THE LINE GRAPH ------------------------------------------------------------------------------
      function drawLineGraph() {
          var width_ratio = .8;
          if (getWidth() * width_ratio > 1000){
              width_ratio = 1000 / getWidth();
          }
          var height_ratio = .7;

          var margin = {top: 100, right: 20, bottom: 70, left: 70},//30,50
              width = (getWidth() * width_ratio) - margin.left - margin.right,
              height = (width * height_ratio) - margin.top - margin.bottom;

          //var formatDate = d3.time.format("%M");

          var x = d3.scaleLinear()
              .range([0, width]);
          var y = d3.scaleLinear()
              .range([height, 0]); // - (height/20
          var xAxis = d3.axisBottom(x).ticks(20);
          var yAxis = d3.axisLeft(y)
              .ticks(20)
              .tickSizeInner(-width)
              .tickSizeOuter(0);

          var line = d3.line()
              .x(function (d, i) {
                  return x(i);
              })
              .y(function (d) {
                  return y(d / minutes_count[0] * 100);
              });

          var svg = d3.select("#chart_1").append("svg")  //PLACEMENT GOES HERE  <---------------
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
              .append("g")
              .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

          x.domain(d3.extent(minutes_count, function (d, i) {
              return (i);
          }));
          y.domain(d3.extent(minutes_count, function (d) {
              return (d / minutes_count[0] * 100);
          }));

          svg.append("g") //x axis
              .attr("class", "x axis")
              .attr("transform", "translate(0," + height + ")")
              .call(xAxis);

          svg.append("text")// x axis label
              .attr("class", "x axis")
              .attr("text-anchor", "middle")
              .attr("x", width / 2)
              .attr("y", height)
              .attr("dy", ((height / 20) + 20) + 'px')
              .text("Time Spent on Assignment (Minutes)")
              .style('font-size', 14);

          svg.append("g") // y axis
              .attr("class", "y axis")
              .call(yAxis);

          svg.append("text") // y axis label
              .attr("transform", "rotate(-90)")
              .attr("x", -height / 2)
              .attr("dy", "-3em")
              .style("text-anchor", "middle")
              .text("Students (%)")
              .style('font-size', 14);

          svg.append("text")// Title
              .attr("class", "x axis")
              .attr("text-anchor", "middle")
              .attr("x", (width / 2))//+300)
              .attr("y", 0)
              .attr("dy", '-1.5em')
              .text("Time Spent by Students on Exercise")
              .style('font-size', 20)
              .style('text-decoration', 'underline');

          svg.append("path")
              .datum(minutes_count)
              .attr("class", "line")
              .attr('id', 'myPath')
              .attr("stroke", "orange")
              .attr("stroke-width", 5)
              .attr("fill", "none")
              .attr("d", line);
      }

      drawLineGraph();

      // DRAW THE SECOND GRAPH ------------------------------------------------------------------------------
      function drawBarGraph() {
          var groupWidth = 5;
          var groupRanges = 0;
          var workingTimeGroups = [];

          do {
              var clusterCount = 0;
              for (var i = 0; i < minutes_array.length; i++) {
                  if ((minutes_array[i] >= groupRanges) && (minutes_array[i] < (groupRanges + groupWidth))) {
                      clusterCount++;
                  }
              }
              workingTimeGroups.push(clusterCount);
              groupRanges += groupWidth;
          }
          while (groupRanges < maximum_minutes);

          var clusterCount = 0,
              sum = 0,
              maxVal = 0;
          for (var i = 0; i < minutes_array.length; i++) {
              if (minutes_array[i] > maximum_minutes) {
                  currentValue = minutes_array[i];
                  sum += currentValue;
                  if (currentValue > maxVal) {
                      maxVal = currentValue;
                  }
                  clusterCount++;
              }
          }
          // ToDo: Take care of x axis description if this is added
          // workingTimeGroups.push(clusterCount);

          var maxStudentsInGroup = Math.max.apply(Math, workingTimeGroups);

          var width_ratio = .8;

          // Scale width to fit into bootsrap container
          if (getWidth() * width_ratio > 1000){
              width_ratio = 1000 / getWidth();
          }

          var height_ratio = .7;

          var margin = {top: 100, right: 20, bottom: 70, left: 70},
              width = (getWidth() * width_ratio) - margin.left - margin.right,
              height = (width * height_ratio) - margin.top - margin.bottom;

          var x = d3.scaleBand()
              .rangeRound([0, width])
              .paddingInner(0.1)
              .domain(workingTimeGroups.map(function (d, i) {
                  return i * groupWidth;
              }));

          var xAxis = d3.axisBottom(x)
              .ticks(10)
              .tickValues(x.domain().filter(function(d, i){
                  return (d % 10) === 0
              }))
              .tickFormat(function(d) { return d + "-" + (d + groupWidth) });

          var y = d3.scaleLinear()
              .domain([0, maxStudentsInGroup])
              .range([height, 0]);

          var yAxis = d3.axisLeft(y)
              .ticks(10);

          var tip = d3.tip()
              .attr('class', 'd3-tip')
              .offset([-10, 0])
              .html(function(_event, d) {
                  return "<strong>Students: </strong><span style='color:orange'>" + d + "</span>";
              });

          var svg = d3.select("#chart_2").append("svg")
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
              .append("g")
              .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

          svg.call(tip);

          svg.append("g")
              .attr("class", "x axis")
              .attr("transform", "translate(0," + height + ")")
              .call(xAxis)
              .selectAll("text")
              .style("text-anchor", "end")
              .attr("dx", "-.8em")
              .attr("dy", ".15em")
              .attr("transform", function(d) {
                  return "rotate(-45)"
              });

          svg.append("g")
              .attr("class", "y axis")
              .call(yAxis)
              .append("text")
              .attr("transform", "rotate(-90)")
              .attr("y", 6)
              .attr("dy", ".71em");

          svg.append("text")
              .attr("transform", "rotate(-90)")
              .attr("x", -height / 2)
              .attr("dy", "-3em")
              .style("text-anchor", "middle")
              .text("Students")
              .style('font-size', 14);

          svg.append("text")
              .attr("class", "x axis")
              .attr("text-anchor", "middle")
              .attr("x", width / 2)
              .attr("y", height)
              .attr("dy", ((height / 20) + 40) + 'px')
              .text("Working Time (Minutes)")
              .style('font-size', 14);

          svg.selectAll(".bar")
              .data(workingTimeGroups)
              .enter().append("rect")
              .attr("class", "bar")
              .attr("x", function(d, i) {
                  return x(i * groupWidth);
              })
              .attr("width", x.bandwidth())
              .attr("y", function(d) { return y(d); })
              .attr("height", function(d) { return height - y(d); })
              .on('mouseenter', tip.show)
              .on('mouseout', tip.hide);

          svg.append("text")
              .attr("class", "x axis")
              .attr("text-anchor", "middle")
              .attr("x", (width / 2))
              .attr("y", 0)
              .attr("dy", '-1.5em')
              .text("Distribution of Time Spent by Students")
              .style('font-size', 20)
              .style('text-decoration', 'underline');
      }

      drawBarGraph();
  }

});
