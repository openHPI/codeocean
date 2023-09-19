$(document).on('turbolinks:load', function () {

    if ($.isController('programming_groups') && window.location.pathname.includes('programming_groups/new')) {
        function is_other_user(user) {
            return !_.isEqual(current_user, user);
        }

        function is_other_session(other_session_id) {
            return session_id !== other_session_id;
        }

        const matching_page = $('#matching');
        const exercise_id = matching_page.data('exercise-id');
        let session_id;

        App.pp_matching = App.cable.subscriptions.create({
            channel: "PpMatchingChannel", exercise_id: exercise_id
        }, {


            connected() {
                // Called when the subscription is ready for use on the server
            },

            disconnected() {
                // Called when the subscription has been terminated by the server
            },

            received(data) {
                // Called when there's incoming data on the websocket for this channel
                switch (data.action) {
                    case 'invited':
                        if (!is_other_user(data.user)) {
                            window.location.reload();
                        }
                        break;
                }
            },
        });
    }
});
