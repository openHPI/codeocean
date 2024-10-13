$(document).on('turbolinks:load', function () {
    const TAB_KEY_CODE = 9;

    let execution_environments;
    let file_types;
    const editors = [];

    var initializeEditor = function (index, element) {
        const editor = ace.edit(element);
        const element_selector = $(element);

        const document = editor.getSession().getDocument();
        // insert pre-existing code into editor. we have to use insertFullLines, otherwise the deltas are not properly added
        const file_id = element_selector.data('file-id');
        let content = $(`.editor-content[data-file-id=${file_id}]`);

        document.insertFullLines(0, content.text().split(/\n/));
        // remove last (empty) that is there by default; disabled due to missing last line
        // document.removeFullLines(document.getLength() - 1, document.getLength() - 1);
        editor.setReadOnly(element_selector.data('read-only') !== undefined);
        editor.setShowPrintMargin(false);
        editor.setTheme(CodeOceanEditor.THEME);
        editors.push(editor);

        // For creating / editing an exercise
        let textarea = $(`textarea[id="exercise_files_attributes_${index}_content"]`);
        if ($('.edit_tip, .new_tip').isPresent()) {
            textarea = $('textarea[id="tip_example"]')
        }
        content = textarea.val();

        if (content !== undefined) {
            editor.getSession().setValue(content);
            editor.getSession().on('change', function () {
                textarea.val(editor.getSession().getValue());
            });
        }

        editor.commands.bindKey("ctrl+alt+0", null);
        const session = editor.getSession();
        session.setMode(element_selector.data('mode'));
        session.setTabSize(element_selector.data('indent-size'));
        session.setUseSoftTabs(true);
        session.setUseWrapMode(true);
    }

    const handleAceThemeChangeEvent = function(_event) {
        editors.forEach(function (editor) {
            editor.setTheme(CodeOceanEditor.THEME);
        }.bind(this));
    };

    $(document).on('theme:change:ace', handleAceThemeChangeEvent.bind(this));

    var initializeEditors = function () {
        // initialize ace editors for all code textareas in the dom except the last one. The last one is the dummy area for new files, which is cloned when needed.
        // this one must NOT! be initialized.
        $('.editor:not(:last)').each(initializeEditor)
    };

    var addFileForm = function (event) {
        event.preventDefault();
        const element = $('#dummies').children().first().clone();

        // the timestamp is used here, since it is most probably unique. This is strange, but was originally designed that way.
        const latestTextAreaIndex = new Date().getTime();
        const html = $('<div>').append(element).html().replace(/index/g, latestTextAreaIndex);
        $('#files').append(html);

        const editor = $('#files .editor').last()[0];
        $('#files li:last select[name*="file_type_id"]').val(getSelectedExecutionEnvironment().file_type_id)
          .on('change chosen:ready', function(event, _parameter) {
            const selectedFileType = event.target.value;
            CodeOceanEditor.updateEditorModeToFileTypeID(editor, selectedFileType);
        });
        $('#files li:last select').chosen(window.CodeOcean.CHOSEN_OPTIONS);

        // initialize the ace editor for the new textarea.
        // pass the correct index and the last ace editor under the node files. this is the last one, since we just added it.
        initializeEditor(latestTextAreaIndex, editor);

        $('#files li:last>div:last').removeClass('in').addClass('show')
        $('body, html').scrollTo('#add-file');
    };

    var removeFileForm = function (fileUrl) {
        // validate fileUrl
        const matches = fileUrl.match(/files\/(\d+)/);
        if (matches) {
            // select the file form based on the delete button
            const fileForm = $(`*[data-file-url="${fileUrl}"]`).parent().parent().parent();
            fileForm.remove();

            // now remove the hidden input representing the file
            const fileId = matches[1];
            const input = $(`input[type="hidden"][value="${fileId}"]`)
            input.remove()
        }
    }

    var deleteFile = function (event) {
        event.preventDefault();
        const fileUrl = $(event.target).data('file-url');

        if (confirm(I18n.t('shared.confirm_destroy'))) {
            const jqxhr = $.ajax({
                // normal file path (without json) would destroy the context object (the exercise) as well, due to redirection
                // to the context after the :destroy action.
                dataType: 'json',
                method: 'DELETE',
                url: fileUrl,
            });
            jqxhr.done(function () {
                removeFileForm(fileUrl)
            });
            jqxhr.fail(ajaxError);
        }
    }

    var ajaxError = function (response) {
        const responseJSON = ((response || {}).responseJSON || {});
        const message = responseJSON.message || responseJSON.error || '';

        $.flash.danger({
            text: message.length > 0 ? message : $('#flash').data('message-failure'),
            showPermanent: response.status === 422,
        });
    };

    var buildCheckboxes = function () {
        $('tbody tr').each(function (index, element) {
            const td = $('td.public', element);
            const checkbox = $('<input>', {
                checked: td.data('value'),
                type: 'checkbox',
                class: 'form-check-input',
            });
            td.on('click', function (event) {
                if (event.target !== this) {
                    // We don't want to trigger the handler when clicking directly on the checkbox.
                    return;
                }
                event.preventDefault();
                checkbox.prop('checked', !checkbox.prop('checked'));
            });
            td.html(checkbox);
        });
    };

    var discardFile = function (event) {
        event.preventDefault();
        $(this).parents('li').remove();
    };

    var enableBatchUpdate = function () {
        $('thead .batch a').on('click', function (event) {
            event.preventDefault();
            if (!$(event.target).data('toggled')) {
                $(event.target).data('toggled', true);
                $(event.target).text($(event.target).data('text'));
                buildCheckboxes();
            } else {
                performBatchUpdate();
            }
        });
    };

    var enableInlineFileCreation = function () {
        $('#add-file').on('click', addFileForm);
        $('#files').on('click', 'li .discard-file', discardFile);
        $('form.edit_exercise, form.new_exercise').on('submit', function () {
            $('#dummies').html('');
        });
        $('.delete-file').on('click', deleteFile);
    };

    var findFileTypeByFileExtension = function (file_extension) {
        return _.find(file_types, function (file_type) {
            return file_type.file_extension === file_extension;
        }) || {};
    };

    var getSelectedExecutionEnvironment = function () {
        return _.find(execution_environments, function (execution_environment) {
            return execution_environment.id === parseInt($('#exercise_execution_environment_id').val());
        }) || {};
    };

    var initializeSortable = function() {
        const nestedQuery = '.nested-sortable-list';
        const root = document.getElementById('tip-list');
        const containers = document.querySelectorAll(nestedQuery);

        function serialize(sortable) {
            let serialized = [];
            for (const child of sortable.children) {
                const nested = child.querySelector(nestedQuery);
                serialized.push({
                    tip_id: child.dataset['tipId'],
                    id: child.dataset['id'],
                    children: nested ? serialize(nested) : []
                });
            }
            return serialized
        }

        function updateTipsJSON(event) {
            const input = $('#tips-json');
            input.val(JSON.stringify(serialize(root)));
            if (event) {
                event.preventDefault();
            }
        }

        function initializeSortable(element) {
            new Sortable(element, {
                group: 'nested',
                animation: 150,
                fallbackOnBody: true,
                swapThreshold: 0.45,
                handle: '.fa-bars',
                onSort: updateTipsJSON
            });
        }

        function removeTip(e) {
            e.preventDefault();
            const row = $(this).parent();
            row.remove();
            updateTipsJSON();
        }

        $('.remove-tip').on('click', removeTip);

        function addTip(id, title) {
            const tip = {id: _.escape(id), title: _.escape(title)}
            const template =
                `<div class="list-group-item d-block" data-tip-id=${tip.id} data-id="">` +
                '<span class="fa-solid fa-bars me-3"></span>' + tip.title +
                `<a class="fa-regular fa-eye ms-2" href="${Routes.tip_path(tip.id)}" target="_blank"></a>` +
                '<a class="fa-solid fa-xmark ms-2 remove-tip" href="#""></a>' +
                '<div class="list-group nested-sortable-list"></div>' +
                '</div>';
            const tipList = $('#tip-list').append(template);
            tipList.find('.remove-tip').last().on('click', removeTip);
            const nestedList = tipList.find('.nested-sortable-list').last().get()[0];
            initializeSortable(nestedList);
        }

        $('#add-tips').on('click', function (e) {
            e.preventDefault();
            const chosenInputTips = $('#tip-selection').find('select');
            const selectedTips = chosenInputTips[0].selectedOptions;
            for (let i = 0; i < selectedTips.length; i++) {
                addTip(selectedTips[i].value, selectedTips[i].label);
            }
            bootstrap.Modal.getInstance($('#add-tips-modal'))?.hide();
            updateTipsJSON();
            chosenInputTips.val('').trigger("chosen:updated");
        });

        for (let i = 0; i < containers.length; i++) {
            initializeSortable(containers[i]);
        }

        updateTipsJSON();
    };

    var highlightCode = function () {
        $('pre code').each(function (index, element) {
            hljs.highlightElement(element);
        });
    };

    var inferFileAttributes = function () {
        $(document).on('change', 'input[type="file"]', function () {
            const filename = $(this).val().split(/[\\/]/g).pop();
            const file_extension = filename.includes('.') ? '.' + filename.split('.')[1] : '';
            const file_type = findFileTypeByFileExtension(file_extension);
            const name = filename.split('.')[0];
            const parent = $(this).parents('li');
            parent.find('input[name*="name"]').val(name);
            parent.find('select[name*="file_type_id"]').val(file_type.id).trigger('chosen:updated');
        });
    };

    var insertTabAtCursor = function (textarea) {
        const selection_start = textarea.get(0).selectionStart;
        const selection_end = textarea.get(0).selectionEnd;
        textarea.val(textarea.val().substring(0, selection_start) + "\t" + textarea.val().substring(selection_end));
        textarea.get(0).selectionStart = selection_start + 1;
        textarea.get(0).selectionEnd = selection_start + 1;
    };

    var observeFileRoleChanges = function () {
        $(document).on('change', 'select[name$="[role]"]', function () {
            const is_test_file = $(this).val() === 'teacher_defined_test' || $(this).val() === 'teacher_defined_linter';
            const parent = $(this).parents('.card');
            const fields = parent.find('.test-related-fields');
            if (is_test_file) {
                fields.slideDown();
            } else {
                fields.slideUp();
                parent.find('[name$="[feedback_message]"]').val('');
                parent.find('[name$="[weight]"]').val(1);
                parent.find('[name$="[hidden_feedback]"]').prop('checked', false);
            }
        });
    };

    const exercise_execution_environment_id_selector = $('#exercise_execution_environment_id');
    const exercise_unpublished_selector = $('#exercise_unpublished');

    let old_execution_environment = exercise_execution_environment_id_selector.val();
    var observeExecutionEnvironment = function () {
        exercise_execution_environment_id_selector.on('change', function () {
            const new_execution_environment = exercise_execution_environment_id_selector.val();

            if (new_execution_environment === '' && !exercise_unpublished_selector.prop('checked')) {
                if (confirm(I18n.t('exercises.form.unpublish_warning'))) {
                    exercise_unpublished_selector.prop('checked', true);
                } else {
                    return exercise_execution_environment_id_selector.val(old_execution_environment).trigger("chosen:updated");
                }
            }
            old_execution_environment = new_execution_environment;
        });
    };

    var observeUnpublishedState = function () {
        exercise_unpublished_selector.on('change', function () {
            if (exercise_unpublished_selector.prop('checked')) {
                if (!confirm(I18n.t('exercises.form.unpublish_warning'))) {
                    exercise_unpublished_selector.prop('checked', false);
                }
            } else if (exercise_execution_environment_id_selector.val() === '') {
                alert(I18n.t('exercises.form.no_execution_environment_selected'));
                exercise_unpublished_selector.prop('checked', true);
            }
        })
    };

    const body_selector = $('body');
    var observeExportButtons = function () {
        $('.export-start').on('click', function (e) {
            e.preventDefault();
            new bootstrap.Modal($('#export-modal')).show();
            exportExerciseStart($(this).data().exerciseId);
        });
        body_selector.on('click', '.export-retry-button', function () {
            exportExerciseStart($(this).data().exerciseId);
        });
        body_selector.on('click', '.export-action', function () {
            exportExerciseConfirm($(this).data().exerciseId);
        });
    }

    var exportExerciseStart = function (exerciseID) {
        const $exerciseDiv = $('#export-exercise');
        const $messageDiv = $exerciseDiv.children('.export-message');
        const $actionsDiv = $exerciseDiv.children('.export-exercise-actions');

        $messageDiv.removeClass('export-failure');

        $messageDiv.html(I18n.t('exercises.export_codeharbor.checking_codeharbor'));
        $actionsDiv.html('<div class="spinner-border"></div>');

        return $.ajax({
            type: 'POST',
            url: Routes.export_external_check_exercise_path(exerciseID),
            dataType: 'json',
            success: function (response) {
                $messageDiv.html(response.message);
                return $actionsDiv.html(response.actions);
            },
            error: function (a, b, c) {
                return alert(`error: ${c}`);
            }
        });
    };

    var exportExerciseConfirm = function (exerciseID) {
        const $exerciseDiv = $('#export-exercise');
        const $messageDiv = $exerciseDiv.children('.export-message');
        const $actionsDiv = $exerciseDiv.children('.export-exercise-actions');

        return $.ajax({
            type: 'POST',
            url: Routes.export_external_confirm_exercise_path(exerciseID),
            dataType: 'json',
            success: function (response) {
                $messageDiv.html(response.message)
                $actionsDiv.html(response.actions);

                if (response.status === 'success') {
                    $messageDiv.addClass('export-success');
                    setTimeout((function () {
                        bootstrap.Modal.getInstance($('#export-modal'))?.hide();
                        $messageDiv.html('').removeClass('export-success');
                    }), 3000);
                } else {
                    $messageDiv.addClass('export-failure');
                }
            },
            error: function (a, b, c) {
                return alert(`error: ${c}`);
            }
        });
    };

    var overrideTextareaTabBehavior = function () {
        $('.mb-3 textarea[name$="[content]"]').on('keydown', function (event) {
            if (event.which === TAB_KEY_CODE) {
                event.preventDefault();
                insertTabAtCursor($(this));
            }
        });
    };

    var performBatchUpdate = function () {
        const jqxhr = $.ajax({
            data: {
                exercises: _.map($('tbody tr'), function (element) {
                    return {
                        id: $(element).data('id'),
                        public: $('.public input', element).prop('checked')
                    };
                })
            },
            dataType: 'json',
            method: 'PUT'
        });
        jqxhr.done(window.CodeOcean.refresh);
        jqxhr.fail(ajaxError);
    };

    var toggleCodeHeight = function () {
        $('code').on('click', function () {
            $(this).css({
                'max-height': 'initial'
            });
        });
    };

    var updateFileTemplates = function (fileType) {
        const jqxhr = $.ajax({
            url: Routes.by_file_type_file_templates_path(fileType),
            dataType: 'json'
        });
        jqxhr.done(function (response) {
            const noTemplateLabel = $('#noTemplateLabel').data('text');
            let options = "<option value>" + noTemplateLabel + "</option>";
            for (let i = 0; i < response.length; i++) {
                options += "<option value='" + response[i].id + "'>" + response[i].name + "</option>"
            }
            $("#code_ocean_file_file_template_id").find('option').remove().end().append($(options));
        });
        jqxhr.fail(ajaxError);
    }

    if ($.isController('exercises') || $.isController('submissions')) {
        // ignore tags table since it is in the dom before other tables
        if ($('table:not(#tags-table)').isPresent()) {
            enableBatchUpdate();
            observeExportButtons();
        } else if ($('.edit_exercise, .new_exercise').isPresent()) {
            const form_selector = $('form');
            execution_environments = form_selector.data('execution-environments');
            file_types = form_selector.data('file-types');

            initializeSortable();
            enableInlineFileCreation();
            inferFileAttributes();
            observeFileRoleChanges();
            observeExecutionEnvironment();
            observeUnpublishedState();
            overrideTextareaTabBehavior();
        } else if ($('#files.jstree').isPresent()) {
            const fileTypeSelect = $('#code_ocean_file_file_type_id');
            if (fileTypeSelect.length > 0) {
                fileTypeSelect.on("change", function () {
                    updateFileTemplates(fileTypeSelect.val())
                });
                updateFileTemplates(fileTypeSelect.val());
            }
        } else if ($('.export-start').isPresent()) {
            observeExportButtons();
        }
        toggleCodeHeight();
    }

    if (window.hljs) {
        highlightCode();
    }

    if ($('#editor-edit').isPresent()) {
        initializeEditors();
        $('.frame').show();
    }


});
