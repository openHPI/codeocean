var setup_programming_language = (function() {
    var select = $('.proglang-select');
    select.chosen({
        disable_search_threshold: 0,
        no_results_text: "No results match. Press enter to add"
    });

    var version_select = $('.version-select');
    version_select.chosen({
        disable_search_threshold: -1,
        no_results_text: "No results match. Press enter to add"
    });

    function update_version_select() {
        var version_select = $('.version-select');
        $(version_select).empty();
        $(version_select).attr("disabled", false);
    }

    var obs = $(select).chosen().data('chosen');
    obs.search_field.on('keyup', function(e){
        if (event.keyCode === 13) {

            var option = $("<option>").val(this.value).text(this.value);
            // Add the new option
            select.prepend(option);
            // Automatically select it
            select.find(option).prop('selected', true).change();
            // Trigger the update
            select.trigger("chosen:close");
            select.trigger("chosen:updated");
        }
    });

    var obs2 = $(version_select).chosen().data('chosen');
    obs2.search_field.on('keyup', function(e){
        if (event.keyCode === 13) {
            var option = $("<option>").val(this.value).text(this.value);
            // Add the new option
            version_select.prepend(option);
            // Automatically select it
            version_select.find(option).prop('selected', true).change();
            // Trigger the update
            version_select.trigger("chosen:close");
            version_select.trigger("chosen:updated");
        }
    });

    select.change(function(){
        var option = $(select).children(':selected').text();
        console.log(option);
        $.ajax({
            type: "GET",
            url: "/execution_environments/proglang_versions",
            data: {proglang: option},
            dataType: 'json',
            success: function (data) {
                // the next thing you want to do
                update_version_select();
                for (var i = 0; i < data.length; i++) {
                    version_select.append('<option value=' + data[i].version + '>' + data[i].version + '</option>');
                }
                version_select.val('');
                version_select.trigger("chosen:updated")
            }
        });
    });

    version_select.change(function(){
        $('.add-button').attr("disabled", false);
    });
});

var show_programming_language_values = (function() {
    $('.nested-fields').each(function() {
        var name = $(this).find('.hidden-name').val();
        var version = $(this).find('.hidden-version').val();
        var is_default = $(this).find('.hidden-default').val();
        $(this).find('.name').html(document.createTextNode(name));
        $(this).find('.version').html(document.createTextNode(version));
        $(this).find('.default').html(document.createTextNode(is_default ? "Yes" : "No"));
    });
});

$(function() {
  if ($.isController('execution_environments')) {
    if ($('.edit_execution_environment, .new_execution_environment').isPresent()) {
      new MarkdownEditor('#execution_environment_help');
      setup_programming_language();
      show_programming_language_values();
    }
  }
});


$(function() {
    $("a.add_fields").
    data("association-insertion-method", 'append').
    data("association-insertion-node", '.table-body');

    $('.table-body').on('cocoon:after-insert', function(e, added_task) {
        // e.g. set the background of inserted task
        var name = $('.proglang-select :selected').text();
        var version = $('.version-select :selected').text();
        var is_default = $('.default-checkbox').prop("checked");
        $(added_task).find('.name').html(document.createTextNode(name));
        $(added_task).find('.version').html(document.createTextNode(version));
        $(added_task).find('.default').html(document.createTextNode(is_default ? "Yes" : "No"));
        $(added_task).find('.hidden-name').val(name);
        $(added_task).find('.hidden-version').val(version);
        $(added_task).find('.hidden-default').val(is_default);
    });
});