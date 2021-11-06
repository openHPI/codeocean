$(document).on('turbolinks:load', function() {
    if ($.isController('exercises') && $('.teacher_dashboard').isPresent()) {

        const exercise_id = $('.teacher_dashboard').data().exerciseId;
        const study_group_id = $('.teacher_dashboard').data().studyGroupId;

        $("tbody#posted_rfcs").children().each(function() {
            let $row = $(this);
            addClickEventToRfCEntry($row);
        });

        function addClickEventToRfCEntry($row) {
            $row.click(function () {
                Turbolinks.visit($(this).data("href"));
            });
        }

        const specific_channel = { channel: "LaExercisesChannel", exercise_id: exercise_id, study_group_id: study_group_id };


        App.la_exercise = App.cable.subscriptions.create(specific_channel, {
            connected: function () {
                // Called when the subscription is ready for use on the server
            },

            disconnected: function () {
                // Called when the subscription has been terminated by the server
            },

            received: function (data) {
                // Called when there's incoming data on the websocket for this channel
                if (data.type === 'rfc') {
                    handleNewRfCdata(data);
                } else if (data.type === 'working_times') {
                    handleWorkingTimeUpdate(data.working_time_data)
                }
            }
        });

        function handleNewRfCdata(data) {
            let $row = $('tr[data-id="' + data.id + '"]');
            if ($row.length === 0) {
                $row = $($('#posted_rfcs')[0].insertRow(0));
            }
            const $html = $(data.html);
            $row.replaceWith($html);
            $row = $html;
            $row.find('time').timeago();
            addClickEventToRfCEntry($row);
        }

        function handleWorkingTimeUpdate(data) {
            const user_progress = data['user_progress'];
            const additional_user_data = data['additional_user_data'];

            const user = additional_user_data[additional_user_data.length - 1][0];
            const position = userPosition[user.type + user.id]; // TODO validate: will result in undef. if not existent.
            // TODO: Do update
        }

        const graph_data = $('#initial_graph_data').data('graph_data');
        let userPosition = {};

        drawGraph(graph_data);

        function drawGraph(graph_data) {
            const user_progress = graph_data['user_progress'];
            const additional_user_data = graph_data['additional_user_data'];
            const user_info = additional_user_data.length - 1;
            const learners = additional_user_data[user_info]

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

            function learners_name(index) {
                return additional_user_data[user_info][index]["name"] + ", ID: " + additional_user_data[user_info][index]["id"];
            }

            function learners_time(group, index) {
                if (user_progress[group] !== null && user_progress[group] !== undefined && user_progress[group][index] !== null) {
                    return user_progress[group][index]
                } else {
                    return 0;
                }
            }

            if (user_progress.length === 0) {
                // No data available
                $('#no_chart_data').removeClass("d-none");
                return;
            }

            const margin = ({top: 20, right: 20, bottom: 150, left: 80});
            const width = $('#chart_stacked').width();
            const height = 500;
            const users = user_progress[0].length; // # of users
            const n = user_progress.length; // # of different sub bars, called buckets

            let working_times_in_minutes = d3.range(n).map((index) => {
                if (user_progress[index] !== null) {
                    return user_progress[index].map((time) => get_minutes(time))
                } else return new Array(users).fill(0);
            });

            let xAxis = svg => svg.append("g")
                .attr("transform", `translate(0,${height - margin.bottom})`)
                .call(d3.axisBottom(x).tickSizeOuter(0).tickFormat((index) => learners_name(index)));

            let yAxis = svg => svg.append("g")
                .attr("transform", `translate(${margin.left}, 0)`)
                .call(d3.axisLeft(y).tickSizeOuter(0).tickFormat((index) => index));

            let color = d3.scaleSequential(d3.interpolateRdYlGn)
                .domain([-0.5 * n, 1.5 * n]);

            let userAxis = d3.range(users); // the x-values shared by all series

            // Calculate the corresponding start and end value of each value;
            const yBarValuesGrouped = d3.stack()
                .keys(d3.range(n))
                (d3.transpose(working_times_in_minutes)) // stacked working_times_in_minutes
                .map((data, i) => data.map(([y0, y1]) => [y0, y1, i]));

            const maxYSingleBar = d3.max(working_times_in_minutes, y => d3.max(y));

            const maxYBarStacked = d3.max(yBarValuesGrouped, y => d3.max(y, d => d[1]));

            let x = d3.scaleBand()
                .domain(userAxis)
                .rangeRound([margin.left, width - margin.right])
                .padding(0.08);

            let y = d3.scaleLinear()
                .domain([0, maxYBarStacked])
                .range([height - margin.bottom, margin.top]);

            const svg = d3.select("#chart_stacked")
                .append("svg")
                .attr("width", '100%')
                .attr("height", '100%')
                .attr("viewBox", `0 0 ${width} ${height}`)
                .attr("preserveAspectRatio","xMinYMin meet");

            const rect = svg.selectAll("g")
                .data(yBarValuesGrouped)
                .enter().append("g")
                .attr("fill", (d, i) => color(i))
                .selectAll("rect")
                .data(d => d)
                .join("rect")
                .attr("x", (d, i) => x(i))
                .attr("y", height - margin.bottom)
                .attr("width", x.bandwidth())
                .attr("height", 0)
                .attr("class", (d) => "bar-stacked-"+d[2]);

            svg.append("g")
                .attr("class", "x axis")
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
                .call(yAxis);

            // Y Axis Label
            svg.append("text")
                .attr("transform", "rotate(-90)")
                .attr("x", (-height - margin.top + margin.bottom) / 2)
                .attr("dy", "+2em")
                .style("text-anchor", "middle")
                .text(I18n.t('exercises.study_group_dashboard.time_spent_in_minutes'))
                .style('font-size', 14);

            // X Axis Label
            svg.append("text")
                .attr("class", "x axis")
                .attr("text-anchor", "middle")
                .attr("x", (width + margin.left - margin.right) / 2)
                .attr("y", height)
                .attr("dy", '-1em')
                .text(I18n.t('exercises.study_group_dashboard.learner'))
                .style('font-size', 14);

            let tip = d3.tip()
                .attr('class', 'd3-tip')
                .offset([-10, 0])
                .html(function(_event, _d) {
                    const e = rect.nodes();
                    const i = e.indexOf(this) % learners.length;
                    return "<strong>Student: </strong><span style='color:orange'>" + learners_name(i) + "</span><br/>" +
                        "0: " + learners_time(0, i) + "<br/>" +
                        "1: " + learners_time(1, i) + "<br/>" +
                        "2: " + learners_time(2, i) + "<br/>" +
                        "3: " + learners_time(3, i) + "<br/>" +
                        "4: " + learners_time(4, i);
                });

            svg.call(tip);

            rect.on('mouseenter', tip.show)
                .on('mouseout', tip.hide);

            function transitionGrouped() {
                // Show all sub-bars next to each other
                y.domain([0, maxYSingleBar]);

                rect.transition()
                    .duration(500)
                    .delay((d, i) => i * 20)
                    .attr("x", (d, i) => x(i) + x.bandwidth() / n * d[2])
                    .attr("width", x.bandwidth() / n)
                    .transition()
                    .attr("y", d => y(d[1] - d[0]))
                    .attr("height", d => y(0) - y(d[1] - d[0]));
            }

            function transitionStacked() {
                // Show all sub-bars on top of each other
                y.domain([0, maxYBarStacked]);

                rect.transition()
                    .duration(500)
                    .delay((d, i) => i * 20)
                    .attr("y", d => y(d[1]))
                    .attr("height", d => y(d[0]) - y(d[1]))
                    .transition()
                    .attr("x", (d, i) => x(i))
                    .attr("width", x.bandwidth());
            }

            $('#no_chart_data').addClass("d-none");
            transitionStacked();
            // ToDo: Add button to switch using transitionGrouped();

            buildDictionary(additional_user_data);
        }

        function buildDictionary(users) {
            users[users.length - 1].forEach(function(user, index) {
                userPosition[user.type + user.id] = index;
            });
        }
    }
});
