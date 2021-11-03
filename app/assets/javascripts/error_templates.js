$(document).on('turbolinks:load', function() {
    if ($.isController('error_templates')) {
        const button = $('#add-attribute').find('button')
        button.on('click', function () {
            $.ajax(Routes.attribute_error_template_path(button.data('template-id')), {
                method: 'POST',
                data: {
                    _method: 'PUT',
                    dataType: 'json',
                    error_template_attribute_id: $('#add-attribute').find('select').val()
                }
            }).done(function () {
                location.reload();
            }).fail(function (error) {
                $.flash.danger({text: error.statusText});
            });
        });
    }
});
