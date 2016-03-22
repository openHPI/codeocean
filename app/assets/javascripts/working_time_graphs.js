$(function() {

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

      minutes_array = _.map(working_times,function(item){return get_minutes(item)});
      maximum_minutes = _.max(minutes_array);
      var minutes_count = new Array(maximum_minutes + 1);

      for (var i = 0; i < maximum_minutes; i++){
          for (var j = 0; j < minutes_array[i]; j++){
              if (minutes_count[j] == undefined){
                  minutes_count[j] = 1;
              } else{
                  minutes_count[j] += 1;
              }
          }
      }

      minutes_count[(maximum_minutes + 1)] = 0;
      //$('.graph-functions').html("<p></p>")
      //console.log(minutes_count) // THIS SHOWS THAT THE FINAL VALUES ARE 1 AND NOT ACTUALLY 0

      // good to test at: localhost:3333/exercises/69/statistics

      var width_ratio = .8;
      var height_ratio = .7; // percent of height


      // currently sets as percentage of window width, however, unfortunately
      // is not yet responsive
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

      var margin = {top: 100, right: 20, bottom: 70, left: 70},//30,50
          width = (getWidth() * width_ratio) - margin.left - margin.right,
          height = (width * height_ratio) - margin.top - margin.bottom;

      //var formatDate = d3.time.format("%M");

      var x = d3.scale.linear()
          .range([0, width]);

      var y = d3.scale.linear()
          .range([height,0]); // - (height/20

      var xAxis = d3.svg.axis()
          .scale(x)
          .orient("bottom")
          .ticks(20);

      var yAxis = d3.svg.axis()
          .scale(y)
          .orient("left")
          .ticks(20)
          .innerTickSize(-width)
          .outerTickSize(0);

      var line = d3.svg.line()
          .x(function(d,i) { return x(i); })
          .y(function(d) { return y(d/minutes_count[0]*100); });

      var svg = d3.select("#chart_1").append("svg")  //PLACEMENT GOES HERE  <---------------
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
          .append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

      x.domain(d3.extent(minutes_count, function(d,i) { return (i); }));
      y.domain(d3.extent(minutes_count, function(d) { return (d/minutes_count[0]*100); }));

      svg.append("g") //x axis
          .attr("class", "x axis")
          .attr("transform", "translate(0," + height + ")")
          .call(xAxis);

      svg.append("text")// x axis label
          .attr("class", "x axis")
          .attr("text-anchor", "middle")
          .attr("x", width/2)
          .attr("y", height)
          .attr("dy", ((height/20)+20) + 'px')
          .text("Time Spent on Assignment (Minutes)")
          .style('font-size',14);

      svg.append("g") // y axis
          .attr("class", "y axis")
          .call(yAxis);

      svg.append("text") // y axis label
          .attr("transform", "rotate(-90)")
          .attr("x", -height/2)
          .attr("dy", "-3em")
          .style("text-anchor", "middle")
          .text("Students (%)")
          .style('font-size',14);

      svg.append("text")// Title
          .attr("class", "x axis")
          .attr("text-anchor", "middle")
          .attr("x", (width/2))//+300)
          .attr("y", 0)
          .attr("dy", '-1.5em')
          .text("Time Spent by Students on Exercise")
          .style('font-size',20)
          .style('text-decoration','underline');

      svg.append("path")
          .datum(minutes_count)
          .attr("class", "line")
          .attr('id','myPath')// new
          .attr("stroke", "black")
          .attr("stroke-width", 5)
          .attr("fill", "none")// end new
          .attr("d", line)//---
          .on("mousemove", mMove)//new again
          .append("title");




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



      //svg.append("rect") // border
      //    .attr("x", 0)
      //    .attr("y", 0)
      //    .attr("height", height)
      //    .attr("width", width)
      //    .style("stroke", "#229")
      //    .style("fill", "none")
      //    .style("stroke-width", 3);

  }

});
