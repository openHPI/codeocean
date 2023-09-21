var ProgrammingGroups = {
    session_id: null,

    getStoredViewedPPInfo: function () {
        return localStorage.getItem('viewed_pp_info')
    },

    setStoredViewedPPInfo: function () {
        localStorage.setItem('viewed_pp_info', 'true')
    },

    initializeEventHandler: function () {
        $('#dont_show_info_pp_modal_again').on('click', this.setStoredViewedPPInfo.bind(this));
    },

    is_other_user: function (user) {
        return !_.isEqual(current_user, user);
    },

    is_other_session: function (other_session_id) {
        return this.session_id !== other_session_id;
    },

    contains_own_user: function (users) {
        return users.find(e => ProgrammingGroups.is_other_user(e) === false) !== undefined
    }
};

$(document).on('turbolinks:load', function () {
    const modal = $('#modal-info-pair-programming');
    if (modal.isPresent()) {
        ProgrammingGroups.initializeEventHandler();

        // We only show the modal if the user has not decided to hide it on the current device.
        // Further, the modal is either shown on /implement for a programming group or on /programming_groups/new.
        if (ProgrammingGroups.getStoredViewedPPInfo() !== 'true' &&
            ((window.location.pathname.includes('/implement') && !_.isEqual(current_user, current_contributor)) ||
              window.location.pathname.includes('/programming_groups/new'))) {
            new bootstrap.Modal(modal).show();
        }
    }

    const join_pair_button = $('.join_programming_pair');
    if (join_pair_button.isPresent()) {
        join_pair_button.on('click', function() {
            App.pg_matching?.waiting_for_match();
            CodeOceanEditor.showSpinner(join_pair_button);
        });
    }
});
