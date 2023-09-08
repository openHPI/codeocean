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

        if (ProgrammingGroups.getStoredViewedPPInfo() !== 'true' && !_.isEqual(current_user, current_contributor)) {
            new bootstrap.Modal(modal).show();
        }
    }
});
