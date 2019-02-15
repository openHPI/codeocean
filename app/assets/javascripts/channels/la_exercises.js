$(document).on('turbolinks:load', function() {
    if ($.isController('exercises') && $('.teacher_dashboard').isPresent()) {

        const exercise_id = $('.teacher_dashboard').data().exerciseId;
        const study_group_id = $('.teacher_dashboard').data().studyGroupId;

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
                let $row = $('tr[data-id="' + data.id + '"]');
                if ($row.length === 0) {
                    $row = $($('#posted_rfcs')[0].insertRow(0));
                }
                $row = $row.replaceWithPush(data.html);
                $row.find('time').timeago();
                $row.click(function () {
                    Turbolinks.visit($(this).data("href"));
                });
            }
        });
    }
});
