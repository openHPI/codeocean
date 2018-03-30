var update_version_select = (function() {
    var version_select = $('.version-select');
    $(version_select).empty();
    $(version_select).attr("disabled", false);
});


var setup_programming_language = (function() {

    var proglang_select = $('.proglang-select');
    var version_select = $('.version-select');

    proglang_select.change(function(){
        var option = $(proglang_select).children(':selected').text();
        $.ajax({
            type: "GET",
            url: "/programming_languages/versions",
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

var setup_new_options = (function($obj) {
    var select_box = $obj.chosen().data('chosen');
    select_box.search_field.on('keyup', function(e) {
        if (event.keyCode === 13) {
            console.log("Worse Fail");
            console.log($obj);
            var option = $("<option>").val(this.value).text(this.value);
            // Add the new option
            $($obj).prepend(option);
            // Automatically select it
            $($obj).find(option).prop('selected', true).change();
            // Trigger the update
            $obj.trigger("chosen:close");
            $obj.trigger("chosen:updated");
        }
    });
});

var setup_chosen_fields = (function() {
    var proglang_select = $('.proglang-select');
    proglang_select.chosen({
        disable_search_threshold: 0,
        no_results_text: "No results match. Press enter to add"
    });

    var version_select = $('.version-select');
    version_select.chosen({
        disable_search_threshold: -1,
        no_results_text: "No results match. Press enter to add"
    });

    setup_new_options(proglang_select);
    setup_new_options(version_select);
});

var show_error_message = (function(error) {
    $('<div class="proglang-error alert alert-danger fade in">'+ error +'</div>')
        .insertAfter('.prog-lang-form')
        .delay(3000)
        .slideUp('medium')
        .queue(function() {
            $(this).remove();
        });
});

var show_default = (function($show, $hide){
    $hide.hide();
    $show.show();
});

$(function() {
  if ($.isController('execution_environments')) {
    if ($('.edit_execution_environment, .new_execution_environment').isPresent()) {
      new MarkdownEditor('#execution_environment_help');
      setup_programming_language();
      //show_programming_language_values();
      setup_chosen_fields();
    }
  }
});

$(function() {
    $("a.add_fields").
        data("association-insertion-method", 'append').
        data("association-insertion-node", '.table-body');

    $('.table-body').on('cocoon:before-insert', function(e, added_task) {
        // e.g. set the background of inserted task
        var name = $('.proglang-select :selected').text();
        var version = $('.version-select :selected').text();
        var is_default = $('.default-checkbox').prop("checked");
        $.ajax({
            type: "POST",
            url: "/programming_languages",
            data: {name: name, version: version, is_default: is_default},
            async: false,
            dataType: 'json',
            success: function(data) {
                if (data.error) {
                    show_error_message(data.error);
                    e.preventDefault();
                }
                else {
                    $(added_task).find('.name').html(document.createTextNode(name));
                    $(added_task).find('.version').html(document.createTextNode(version));
                    //$(added_task).find('.default').html(document.createTextNode(is_default ? "Yes" : "No"));
                    var true_node = $(added_task).find('.true');
                    var false_node = $(added_task).find('.false');
                    is_default ? show_default(true_node, false_node) : show_default(false_node, true_node);
                    $(added_task).find('.hidden-default').val(is_default);
                    $(added_task).find('.hidden-id').val(data.id);
                }
            },
            error: function(xhr){
                var errors = $.parseJSON(xhr.responseText).errors;
                console.log(errors);
                for (var i = 0, len = errors.length; i < len; i++) {
                    show_error_message(errors[i]);
                }
                e.preventDefault();
            }
        });
    });
});