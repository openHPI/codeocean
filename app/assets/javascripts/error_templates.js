$(function() {
    if ($.isController('error_templates')) {
        $('#add-attribute').find('button').on('click', function () {
            $.ajax(location + '/attribute.json', {
                method: 'POST',
                data: {
                    _method: 'PUT',
                    dataType: 'json',
                    error_template_attribute_id: $('#add-attribute').find('select').val()
                }
            }).success(function () {
                location.reload();
            }).error(function (error) {
                $.flash.danger({text: error.statusText});
            });
        });
    }
});