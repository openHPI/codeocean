$(function() {
    // http://localhost:3333/exercises/38/statistics good for testing
    // originally at--> localhost:3333/exercises/69/statistics

    if ($.isController('exercises') && $('.graph-functions-2').isPresent()) {
        // GET THE DATA
        var submissions = $('#data').data('submissions');
        var submissions_length = submissions.length;

        submissionsScoreAndTimeAssess = [[0,0]];
        submissionsScoreAndTimeSubmits = [[0,0]];
        var maximumValue = 0;

        var wtimes = $('#wtimes').data('working_times'); //.hidden#wtimes data-working_times=ActiveSupport::JSON.encode(working_times_until)
        
        // console.log(submissions);
        // console.log(wtimes);

        for (var i = 0;i<submissions_length;i++){
            var submission = submissions[i];

            if(submission.cause == "assess"){
                var workingTime = get_minutes(wtimes[i]);
                var submissionArray = [submission.score, 0];

                if (workingTime > 0) {
                    submissionArray[1] = workingTime;
                }

                if(submission.score>maximumValue){
                    maximumValue = submission.score;
                }
                submissionsScoreAndTimeAssess.push(submissionArray);
            } else if(submission.cause == "submit"){
                var workingTime = get_minutes(wtimes[i]);
                var submissionArray = [submission.score, 0];

                if (workingTime > 0) {
                    submissionArray[1] = workingTime;
                }

                if(submission.score>maximumValue){
                    maximumValue = submission.score;
                }
                submissionsScoreAndTimeSubmits.push(submissionArray);
            }
        }
        // console.log(submissionsScoreAndTimeAssess.length);
        // console.log(submissionsScoreAndTimeSubmits);

        function get_minutes (time_stamp) {
            try {
                hours = time_stamp.split(":")[0];
                minutes = time_stamp.split(":")[1];
                seconds = time_stamp.split(":")[2];

                minutes = parseFloat(hours * 60) + parseInt(minutes);
                if (minutes > 0){
                    return minutes;
                } else{
                    return parseFloat(seconds/60);
                }
            } catch (err) {
                return 0;
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

        function graph_assesses() {
            // MAKE THE GRAPH
            var width_ratio = .8;
            var height_ratio = .7; // percent of height

            var margin = {top: 100, right: 20, bottom: 70, left: 70},//30,50
                width = (getWidth() * width_ratio) - margin.left - margin.right,
                height = (width * height_ratio) - margin.top - margin.bottom;

            // Set the ranges
            var x = d3.scale.linear().range([0, width]);
            var y = d3.scale.linear().range([height,0]);

            //var x = d3.scale.linear()
            //    .range([0, width]);
            //var y = d3.scale.linear()
            //    .range([0,height]); // - (height/20

            var xAxis = d3.svg.axis()
                .scale(x)
                .orient("bottom")
                .ticks(20);


            var yAxis = d3.svg.axis()
                .scale(d3.scale.linear().domain([0,maximumValue]).range([height,0]))//y
                // .scale(y)
                .orient("left")
                .ticks(maximumValue)
                .innerTickSize(-width)
                .outerTickSize(0);

            //var line = d3.svg.line()
            //    .x(function(d) { return x(d.date); })
            //    .y(function(d) { return y(d.close); });

            var line = d3.svg.line()
                .x(function (d) {
                    // console.log(d[1]);
                    return x(d[1]);
                })
                .y(function (d) {
                    // console.log(d[0]);
                    return y(d[0]);
                });

            var svg = d3.select("#progress_chart").append("svg")  //PLACEMENT GOES HERE  <---------------
                .attr("width", width + margin.left + margin.right)
                .attr("height", height + margin.top + margin.bottom)
                .append("g")
                .attr("transform", "translate(" + margin.left + "," + margin.top + ")");


            x.domain(d3.extent(submissionsScoreAndTimeAssess, function (d) {
                // console.log(d[1]);
                return (d[1]);
            }));
            y.domain(d3.extent(submissionsScoreAndTimeAssess, function (d) {
                // console.log(d[0]);
                return (d[0]);
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
                .text("Score")
                .style('font-size', 14);

            svg.append("text")// Title
                .attr("class", "x axis")
                .attr("text-anchor", "middle")
                .attr("x", (width / 2))//+300)
                .attr("y", 0)
                .attr("dy", '-1.5em')
                .text("Assesses Timeline")
                .style('font-size', 20)
                .style('text-decoration', 'underline');

            //
            // svg.append("path")
            //    //.datum()
            //    .attr("class", "line")
            //    .attr('id', 'myPath')// new
            //    .attr("stroke", "black")
            //    .attr("stroke-width", 5)
            //    .attr("fill", "none")// end new
            //    .attr("d", line(submissionsScoreAndTimeAssess));//---

            svg.append("path")
                .datum(submissionsScoreAndTimeAssess)
                .attr("class", "line")
                .attr('id', 'myPath')// new
                .attr("stroke", "orange")
                .attr("stroke-width", 5)
                .attr("fill", "none")// end new
                .attr("d", line);//---


            svg.selectAll("dot") // Add dots to assesses
                .data(submissionsScoreAndTimeAssess)
                .enter().append("circle")
                .attr("r", 3.5)
                .attr("cx", function(d) { return x(d[1]); })
                .attr("cy", function(d) { return y(d[0]); });


            svg.append("path")
                .datum(submissionsScoreAndTimeSubmits)
                .attr("class", "line2")
                .attr('id', 'myPath')// new
                .attr("stroke", "blue")
                .attr("stroke-width", 5)
                .attr("fill", "none")// end new
                .attr("d", line);//---

            svg.selectAll("dot") // Add dots to submits
                .data(submissionsScoreAndTimeSubmits)
                .enter().append("circle")
                .attr("r", 3.5)
                .attr("cx", function(d) { return x(d[1]); })
                .attr("cy", function(d) { return y(d[0]); });


            var color_hash = {  0 : ["Submissions", "blue"],
                1 : ["Assesses", "orange"]
            }

            // add legend
            var legend = svg.append("g")
                .attr("class", "legend")
                .attr("x", 65)
                .attr("y", 25)
                .attr("height", 100)
                .attr("width", 100);

            var dataset = [submissionsScoreAndTimeSubmits,submissionsScoreAndTimeAssess];

            legend.selectAll('g').data(dataset)
                .enter()
                .append('g')
                .each(function(d, i) {
                    var g = d3.select(this);
                    g.append("rect")
                        .attr("x", 20)
                        .attr("y", i*25 + 8)
                        .attr("width", 10)
                        .attr("height", 10)
                        .style("fill", color_hash[String(i)][1]);

                    g.append("text")
                        .attr("x", 40)
                        .attr("y", i * 25 + 18)
                        .attr("height",30)
                        .attr("width",100)
                        .style("fill", color_hash[String(i)][1])
                        .text(color_hash[String(i)][0]);

                });



            // function type(d) {
            //     d.frequency = +d.frequency;
            //     return d;
            // }

            //.on("mousemove", mMove)//new again
            //.append("title");

        }

        try{
            graph_assesses();
        } catch(err){
            // not enough data
        }

  }

});
