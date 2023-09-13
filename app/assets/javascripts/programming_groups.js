var ProgrammingGroups = {
    getStoredViewedPPInfo: function () {
        return localStorage.getItem('viewed_pp_info')
    },

    setStoredViewedPPInfo: function () {
        localStorage.setItem('viewed_pp_info', 'true')
    },


    initializeEventHandler: function () {
        $('#dont_show_info_pp_modal_again').on('click', this.setStoredViewedPPInfo.bind(this));
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
});
