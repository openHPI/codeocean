$(document).on('turbolinks:load', function() {
    // /exercises/38/statistics good for testing

    if ($.isController('exercises') && $('.graph-functions-2').isPresent()) {
        var submissions = $('#data').data('submissions');
        var submissions_length = submissions.length;

        submissionsScoreAndTimeAssess = [[0,0]];
        submissionsScoreAndTimeSubmits = [[0,0]];
        submissionsScoreAndTimeRuns = [];
        submissionsSaves = [];
        submissionsAutosaves = [];
        var maximumValue = 0;

        var wtimes = $('#wtimes').data('working_times');

        for (var i = 0;i<submissions_length;i++){
            var submission = submissions[i];
            var workingTime;
            var submissionArray;

            workingTime = get_minutes(wtimes[i]);
            submissionArray = [submission.score, 0];

            if (workingTime > 0) {
                submissionArray[1] = workingTime;
            }
            if(submission.score>maximumValue){
                maximumValue = submission.score;
            }

            if(submission.cause == "assess"){
                submissionsScoreAndTimeAssess.push(submissionArray);
            } else if(submission.cause == "submit"){
                submissionsScoreAndTimeSubmits.push(submissionArray);
            } else if(submission.cause == "run"){
                submissionsScoreAndTimeRuns.push(submissionArray[1]);
            } else if(submission.cause == "autosave"){
                submissionsAutosaves.push(submissionArray[1]);
            }  else if(submission.cause == "save"){
                submissionsSaves.push(submissionArray[1]);
            }
        }

        function get_minutes (time_stamp) {
            try {
                hours = time_stamp.split(":")[0];
                minutes = time_stamp.split(":")[1];
                seconds = time_stamp.split(":")[2];
                seconds /= 60;
                minutes = parseFloat(hours * 60) + parseInt(minutes) + seconds;
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
            if (getWidth()*width_ratio > 1000){
                width_ratio = 1000/getWidth();
            }
            var height_ratio = .7; // percent of height

            var margin = {top: 100, right: 20, bottom: 70, left: 70},//30,50
                width = (getWidth() * width_ratio) - margin.left - margin.right,
                height = (width * height_ratio) - margin.top - margin.bottom;

            // Set the ranges
            var x = d3.scaleLinear().range([0, width]);
            var y = d3.scaleLinear().range([height,0]);

            //var x = d3.scaleLinear()
            //    .range([0, width]);
            //var y = d3.scaleLinear()
            //    .range([0,height]); // - (height/20

            var xAxis = d3.axisBottom(x).ticks(20);
            var yAxis = d3.axisLeft()
                .scale(d3.scaleLinear().domain([0,maximumValue]).range([height,0]))
                .ticks(maximumValue)
                .tickSizeInner(-width)
                .tickSizeOuter(0);

            var line = d3.line()
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

            var largestSubmittedTimeStamp = submissions[submissions_length-1];
            var largestArrayForRange;

            if(largestSubmittedTimeStamp.cause == "assess"){
                largestArrayForRange = submissionsScoreAndTimeAssess;
                x.domain([0,largestArrayForRange[largestArrayForRange.length - 1][1]]).clamp(true);
            } else if(largestSubmittedTimeStamp.cause == "submit"){
                largestArrayForRange = submissionsScoreAndTimeSubmits;
                x.domain([0,largestArrayForRange[largestArrayForRange.length - 1][1]]).clamp(true);
            } else if(largestSubmittedTimeStamp.cause == "run"){
                largestArrayForRange = submissionsScoreAndTimeRuns;
                x.domain([0,largestArrayForRange[largestArrayForRange.length - 1]]).clamp(true);
            } else if(largestSubmittedTimeStamp.cause == "autosave"){
                largestArrayForRange = submissionsAutosaves;
                x.domain([0,largestArrayForRange[largestArrayForRange.length - 1]]).clamp(true);
            } else if(largestSubmittedTimeStamp.cause == "save"){
                largestArrayForRange = submissionsSaves;
                x.domain([0,largestArrayForRange[largestArrayForRange.length - 1]]).clamp(true);
            }
            // take maximum value between assesses and submits
            var yDomain = submissionsScoreAndTimeAssess.concat(submissionsScoreAndTimeSubmits);
            y.domain(d3.extent(yDomain, function (d) {
                // console.log(d[0]);
                return (d[0]);
            }));
            // y.domain([0,2]).clamp(true);

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

            
             svg.append("path")
                //.datum()
                .attr("class", "line")
                .attr('id', 'myPath')// new
                .attr("stroke", "black")
                .attr("stroke-width", 5)
                .attr("fill", "none")// end new
                .attr("d", line(submissionsScoreAndTimeAssess));//---

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

            if (submissionsScoreAndTimeSubmits.length > 0){
              // get rid of the 0 element at the beginning
              submissionsScoreAndTimeSubmits.shift();
            }

            svg.selectAll("dot") // Add dots to submits
                .data(submissionsScoreAndTimeSubmits)
                .enter().append("circle")
                .attr("r", 6)
                .attr("stroke", "black")
                .attr("fill", "blue")
                .attr("cx", function(d) { return x(d[1]); })
                .attr("cy", function(d) { return y(d[0]); });

            for (var i = 0; i < submissionsScoreAndTimeRuns.length; i++) {
                svg.append("line")
                    .attr("stroke", "red")
                    .attr("stroke-width", 1)
                    .attr("fill", "none")// end new
                    .attr("y1", y(0))
                    .attr("y2", 0)
                    .attr("x1", x(submissionsScoreAndTimeRuns[i]))
                    .attr("x2", x(submissionsScoreAndTimeRuns[i]));
            }

            var color_hash = {  0 : ["Submissions", "blue"],
                1 : ["Assesses", "orange"],
                2 : ["Runs", "red"]
            };

            // add legend
            var legend = svg.append("g")
                .attr("class", "legend")
                .attr("x", 65)
                .attr("y", 25)
                .attr("height", 100)
                .attr("width", 100);

            var dataset = [submissionsScoreAndTimeSubmits,submissionsScoreAndTimeAssess, submissionsScoreAndTimeRuns];
            var yOffset = -70;

            legend.selectAll('g').data(dataset)
                .enter()
                .append('g')
                .each(function(d, i) {
                    var g = d3.select(this);
                    g.append("rect")
                        .attr("x", 20)
                        .attr("y", i*25 + yOffset)// + 8
                        .attr("width", 10)
                        .attr("height", 10)
                        .style("fill", color_hash[String(i)][1]);

                    g.append("text")
                        .attr("x", 40)
                        .attr("y", i * 25 + yOffset + 10)// + 18
                        .attr("height",30)
                        .attr("width",100)
                        .style("fill", color_hash[String(i)][1])
                        .text(color_hash[String(i)][0]);

                });
        }

        try{
            graph_assesses();
        } catch(err){
            console.error("Could not draw the graph", err);
        }

  }

});
