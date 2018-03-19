$(function() {
    // http://localhost:3333/exercises/38/statistics good for testing
    // originally at--> localhost:3333/exercises/69/statistics

  if ($.isController('exercises') && $('.graph-functions').isPresent()) {
      var working_times = $('#data').data('working-time');
      
      function get_minutes (time_stamp){
          try{
              hours = time_stamp.split(":")[0];
              minutes = time_stamp.split(":")[1];
              seconds = time_stamp.split(":")[2];

              minutes = parseFloat(hours * 60) + parseInt(minutes);
              return minutes
          } catch (err){
              return 0;
          }

      }

      // GET ALL THE DATA ------------------------------------------------------------------------------
      minutes_array = _.map(working_times,function(item){return get_minutes(item)});
      minutes_array_length = minutes_array.length;

      maximum_minutes = _.max(minutes_array);
      var minutes_count = new Array(maximum_minutes);

      for (var i = 0; i < minutes_array_length; i++){
          var studentTime = minutes_array[i];

          for (var j = 0; j < studentTime; j++){
              if (minutes_count[j] == undefined){
                  minutes_count[j] = 0;
              } else{
                  minutes_count[j] += 1;
              }
          }
      }

      function getWidth() {
          if (self.innerHeight) {
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
      function draw_line_graph() {
          var width_ratio = .8;
          if (getWidth()*width_ratio > 1000){
              width_ratio = 1000/getWidth();
          }
          var height_ratio = .7; // percent of height

          // currently sets as percentage of window width, however, unfortunately
          // is not yet responsive

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
              .attr('id', 'myPath')// new
              .attr("stroke", "orange")
              .attr("stroke-width", 5)
              .attr("fill", "none")// end new
              .attr("d", line);//---
          //.on("mousemove", mMove)//new again
          //.append("title");

          // function type(d) {
          //     d.frequency = +d.frequency;
          //     return d;
          // }
      }

      draw_line_graph();

      // THIS SHOULD DISPLAY THE X AND Y VALUES BUT
      // THE RESULTS ARE WRONG AT THE END FOR SOME REASON

      //function mMove() {
      //    var x_width = getWidth() * width_ratio;
      //    //var x_value = m[0]*(minutes_count.length/x_width);
      //
      //    var y_height = x_width * height_ratio;
      //    //var y_value = (((y_height - m[1])/y_height)*100);
      //
      //    //console.log('y is: ' + y_value);
      //    var m = d3.mouse(this);
      //    d3.select("#myPath").select("title")
      //        .text((y_height-m[1])/(y_height) * 100 + "% of Students" +"\n"+
      //              (m[0]*(minutes_count.length/x_width)) +" Minutes");//text(m[1]);
      //}

      // DRAW THE SECOND GRAPH ------------------------------------------------------------------------------
      //<script src="http://labratrevenge.com/d3-tip/javascripts/d3.tip.v0.6.3.js"></script>
      function draw_bar_graph() {
          var group_incrament = 5;
          var group_ranges = group_incrament; // just for the start
          var minutes_array_for_bar = [];

          do {
              var section_value = 0;
              for (var i = 0; i < minutes_array.length; i++) {
                  if ((minutes_array[i] < group_ranges) && (minutes_array[i] >= (group_ranges - group_incrament))) {
                      section_value++;
                  }
              }
              minutes_array_for_bar.push(section_value);
              group_ranges += group_incrament;
          }
          while (group_ranges < maximum_minutes + group_incrament);

          //console.log(minutes_array_for_bar); // this var used as the bars
          //minutes_array_for_bar = [39, 20, 28, 20, 39, 34, 26, 23, 16, 8];

          var max_of_array = Math.max.apply(Math, minutes_array_for_bar);
          var min_of_array = Math.min.apply(Math, minutes_array_for_bar);


          var width_ratio = .8;
          var height_ratio = .7; // percent of height

          var margin = {top: 100, right: 20, bottom: 70, left: 70},//30,50
              width = (getWidth() * width_ratio) - margin.left - margin.right,
              height = (width * height_ratio) - margin.top - margin.bottom;

          var x = d3.scale.ordinal()
              .rangeRoundBands([0, width], .1);

          var y = d3.scaleLinear()
              .range([0,height-(margin.top + margin.bottom)]);


          var xAxis = d3.svg.axis()
              .scale(x)
              .orient("bottom")
              .ticks(10);


          var yAxis = d3.svg.axis()
              .scale(d3.scaleLinear().domain([0,max_of_array]).range([height,0]))//y
              .orient("left")
              .ticks(10)
              .innerTickSize(-width);

          var tip = d3.tip()
              .attr('class', 'd3-tip')
              .offset([-10, 0])
              .html(function(d) {
                  return "<strong>Students:</strong> <span style='color:orange'>" + d + "</span>";
              });

          var svg = d3.select("#chart_2").append("svg")
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
              .append("g")
              .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

          svg.call(tip);

          x.domain(minutes_array_for_bar.map(function (d, i) {
              i++;
              var high_side = i * group_incrament;
              var low_side = high_side - group_incrament;
              return (low_side+"-"+high_side);
          }));

          y.domain(minutes_array_for_bar.map(function (d) {
              return (d);
          }));

          svg.append("g")
              .attr("class", "x axis")
              .attr("transform", "translate(0," + height + ")")
              .call(xAxis);

          svg.append("g")
              .attr("class", "y axis")
              .call(yAxis)
              .append("text")
              .attr("transform", "rotate(-90)")
              .attr("y", 6)
              .attr("dy", ".71em");
              //.style("text-anchor", "end")
              //.text("Students");

          svg.append("text") // y axis label
              .attr("transform", "rotate(-90)")
              .attr("x", -height / 2)
              .attr("dy", "-3em")
              .style("text-anchor", "middle")
              .text("Students")
              .style('font-size', 14);

          svg.append("text")// x axis label
              .attr("class", "x axis")
              .attr("text-anchor", "middle")
              .attr("x", width / 2)
              .attr("y", height)
              .attr("dy", ((height / 20) + 20) + 'px')
              .text("Working Time (Minutes)")
              .style('font-size', 14);

          y = d3.scaleLinear()
              .domain([(0),max_of_array])
              .range([0,height]);


          svg.selectAll(".bar")
              .data(minutes_array_for_bar)
              .enter().append("rect")
              .attr("class", "bar")
              .attr("x", function(d,i) {    var bar_incriment = width/ minutes_array_for_bar.length;
                                            var bar_x = i * bar_incriment;
                                            return (bar_x)})
              .attr("width", x.rangeBand())
              .attr("y", function(d) { return height - y(d); })
              .attr("height", function(d) { return y(d); })
              .on('mouseover', tip.show)
              .on('mouseout', tip.hide);

          svg.append("text")// Title
              .attr("class", "x axis")
              .attr("text-anchor", "middle")
              .attr("x", (width / 2))//+300)
              .attr("y", 0)
              .attr("dy", '-1.5em')
              .text("Distribution of Time Spent by Students")
              .style('font-size', 20)
              .style('text-decoration', 'underline');

      }
      // draw_bar_graph();
  }

});
