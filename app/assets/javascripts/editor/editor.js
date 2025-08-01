var CodeOceanEditor = {
    THEME: window.getCurrentTheme() === 'dark' ? 'ace/theme/tomorrow_night' : 'ace/theme/tomorrow',

    //Color-Encoding for Percentages in Progress Bars (For submissions)
    ADEQUATE_PERCENTAGE: 50,
    SUCCESSFULL_PERCENTAGE: 90,

    //Key-Codes (for Hotkeys)
    R_KEY_CODE: 82,
    S_KEY_CODE: 83,
    T_KEY_CODE: 84,
    ENTER_KEY_CODE: 13,

    //Request-For-Comments-Configuration
    REQUEST_FOR_COMMENTS_DELAY: 0,
    REQUEST_TOOLTIP_TIME: 5000,
    REQUEST_TOOLTIP_DELAY: 15 * 60 * 1000,

    editors: [],
    editor_for_file: new Map(),
    regex_for_language: new Map(),
    tracepositions_regex: undefined,

    active_file: undefined,
    active_frame: undefined,
    running: false,

    lastCopyText: null,

    sendEvents: null,
    eventURL: Routes.events_path(),
    fileTypeURL: Routes.file_types_path(),

    confirmDestroy: function (event) {
        event.preventDefault();
        if (confirm(I18n.t('shared.confirm_destroy'))) {
            this.destroyFile();
        }
    },

    confirmReset: function (event) {
        event.preventDefault();
        const initiator = $(event.target.closest("button"));
        if (confirm(initiator.data('message-confirm'))) {
            this.resetCode(initiator);
        }
    },

    confirmResetActiveFile: function (event) {
        event.preventDefault();
        const initiator = $(event.target.closest("button"));
        let message = initiator.data('message-confirm');
        message = message.replace('%{filename}', CodeOceanEditor.active_file.filename)
        if (confirm(message)) {
            this.resetCode(initiator, true); // delete only active file
        }
    },

    fileActionsAvailable: function () {
        return this.isActiveFileRenderable() || this.isActiveFileRunnable() || this.isActiveFileStoppable() || this.isActiveFileTestable();
    },

    findOrCreateOutputElement: function (index) {
        if ($('#output-' + index).isPresent()) {
            return $('#output-' + index);
        } else {
            var element = $('<div class="mb-2 output-element">').attr('id', 'output-' + index);
            $('#output').append(element);
            return element;
        }
    },

    getCardClass: function (result) {
        if (result.file_role === 'teacher_defined_linter') {
            return 'info'
        } else if (result.stderr && !result.score) {
            return 'danger';
        } else if (result.score < 1) {
            return 'warning';
        } else {
            return 'success';
        }
    },

    showOutput: function (event) {
        const target = $(event.target).attr('href');
        if (target !== "#") {
            event.preventDefault();
            this.showOutputBar();
            $('body').scrollTo($(event.target).attr('href'));
        }
    },

    renderProgressBar: function (score, maximum_score) {
        var percentage = score / maximum_score * 100;
        var progress_bar = $('#score .progress-bar');
        progress_bar.removeClass().addClass(this.getProgressBarClass(percentage));
        progress_bar.attr({
            'aria-valuemax': maximum_score,
            'aria-valuemin': 0,
            'aria-valuenow': score
        });
        progress_bar.css('width', percentage + '%');
    },

    // The event ready.jstree is fired too early and thus doesn't work.
    selectFileInJsTree: function (filetree, file_id) {
        if (!filetree.is(':visible'))
            // The left sidebar is not shown and thus the filetree is not rendered.
            return;

        if (!filetree.hasClass('jstree-loading')) {
            filetree.jstree("deselect_all");
            filetree.jstree(true).select_node(file_id);
        } else {
            setTimeout(CodeOceanEditor.selectFileInJsTree.bind(null, filetree, file_id), 250);
        }
    },

    showFirstFile: function (own_solution = false) {
        let frame;
        let filetree;
        let editorSelector;
        if (own_solution) {
            frame = $('.own-frame[data-role="main_file"]').isPresent() ? $('.own-frame[data-role="main_file"]') : $('.own-frame').first();
            filetree = $('#own-files');
            editorSelector = '.own-editor';
        } else {
            frame = $('.frame[data-role="main_file"]').isPresent() ? $('.frame[data-role="main_file"]') : $('.frame').first();
            filetree = $('#files');
            editorSelector = '.editor';
        }

        var file_id = frame.find(editorSelector).data('file-id');
        this.setActiveFile(frame.data('filename'), file_id);
        this.selectFileInJsTree(filetree, file_id);
        this.showFrame(frame);
        this.toggleButtonStates();
    },

    showFrame: function (frame) {
        if (frame.hasClass('own-frame')) {
            $('.own-frame').hide();
        } else {
            $('.frame').hide();
        }

        this.active_frame = frame;
        frame.show();
        this.resizeParentOfAceEditor(frame.find('.ace_editor'));
    },

    getProgressBarClass: function (percentage) {
        if (percentage < this.ADEQUATE_PERCENTAGE) {
            return 'progress-bar progress-bar-striped bg-danger';
        } else if (percentage < this.SUCCESSFULL_PERCENTAGE) {
            return 'progress-bar progress-bar-striped bg-warning';
        } else {
            return 'progress-bar progress-bar-striped bg-success';
        }
    },

    handleKeyPress: function (event) {
        if (event.altKey && event.which === this.R_KEY_CODE) {
            $('#run').trigger('click');
        } else if (event.altKey && event.which === this.S_KEY_CODE) {
            $('#assess').trigger('click');
        } else if (event.altKey && event.which === this.T_KEY_CODE) {
            $('#test').trigger('click');
        } else {
            return;
        }
        event.preventDefault();
    },

    handleCopyEvent: function (text) {
        CodeOceanEditor.lastCopyText = text;
    },

    handlePasteEvent: function (pasteObject, event) {
        var same = (CodeOceanEditor.lastCopyText === pasteObject.text);

        // if the text is not copied from within the editor (from any file), send an event to the backend
        if (!same) {
            CodeOceanEditor.publishCodeOceanEvent({
                category: 'editor_paste',
                data: pasteObject.text,
                exercise_id: $('#editor').data('exercise-id'),
                file_id: $(event.container).data('file-id')
            });
        }
    },

    hideSpinner: function () {
        $('button i.fa-solid, button i.fa-regular').show();
        $('button i.fa-spin').removeClass('d-inline-block').addClass('d-none');
    },

    newSentryTransaction: function (initiator, callback) {
        // based on Sentry recommendation.
        // See https://github.com/getsentry/sentry-javascript/issues/12116
        return Sentry.startNewTrace(() => {
            const cause = initiator.data('cause') || initiator.prop('id');
            return Sentry.startSpan({name: cause, op: "transaction"}, async () => {
                // Execute the desired custom code
                try {
                    return await callback();
                } catch (error) {
                    // WebSocket errors are handled in `showWebsocketError` already.
                    if (error.target instanceof WebSocket) return;

                    console.error(error);
                    Sentry.captureException(error, {mechanism: {handled: false, data: {error_json: JSON.stringify(error)}}});
                }
            });
        });
    },

    resizeAceEditors: function (own_solution = false) {
        let editorSelector;
        if (own_solution) {
            editorSelector = $('.own-editor')
        } else {
            editorSelector = $('.editor')
        }

        editorSelector.each(function (index, element) {
            this.resizeParentOfAceEditor(element);
        }.bind(this));
        window.dispatchEvent(new Event('resize'));
    },

    resizeSidebars: function () {
        $('#content-left-sidebar').height(this.calculateEditorHeight('#content-left-sidebar', false));
        $('#content-right-sidebar').height(this.calculateEditorHeight('#content-right-sidebar', false));
    },

    calculateEditorHeight: function (element, considerStatusbar) {
        const jqueryElement = $(element);
        if (jqueryElement.length === 0) {
            return 0;
        }

        const bottom = considerStatusbar ? ($('#statusbar').height() || 0) : 0;
        // calculate needed size: window height - position of top of ACE editor - height of autosave label below editor - 7 for bar margins
        return window.innerHeight - jqueryElement.offset().top - bottom - 7;
    },

    resizeParentOfAceEditor: function (element) {
        const editorHeight = this.calculateEditorHeight(element, true);
        $(element).parent().height(editorHeight);
    },

    initializeEditors: function (own_solution = false) {
        // Initialize the editors array if not present already. This is mainly required for community solutions
        this.editors = this.editors || [];
        let editorSelector;
        if (own_solution) {
            editorSelector = $('.own-editor')
        } else {
            editorSelector = $('.editor')
        }

        editorSelector.each(function (index, element) {

            // Resize frame on load
            this.resizeParentOfAceEditor(element);

            // Resize frame on window size change
            $(window).resize(function () {
                this.resizeParentOfAceEditor(element);
                this.resizeSidebars();
            }.bind(this));

            var editor = ace.edit(element);

            var document = editor.getSession().getDocument();
            // insert pre-existing code into editor. we have to use insertFullLines, otherwise the deltas are not properly added
            var file_id = $(element).data('file-id');
            var content = $('.editor-content[data-file-id=' + file_id + ']');
            this.setActiveFile($(element).parent().data('filename'), file_id);

            const full_lines = content.text().split(/\n/);
            if (full_lines.length >= 1 && full_lines[0] !== "") {
                document.insertFullLines(0, full_lines);
                // remove last (empty) that is there by default line
                document.removeFullLines(document.getLength() - 1, document.getLength() - 1);
                // remove content from DOM, so that it won't be readded during Turbo navigation
                content.text("");
            }

            editor.setReadOnly($(element).parent().data('read-only') !== undefined);
            if (editor.getReadOnly()) {
                editor.setHighlightActiveLine(false);
                editor.setHighlightGutterLine(false);
                editor.renderer.$cursorLayer.element.style.opacity = 0;
            }
            editor.setShowPrintMargin(false);
            editor.setTheme(this.THEME);


            // set options for autocompletion
            if ($(element).data('allow-auto-completion')) {
                editor.setOptions({
                    enableBasicAutocompletion: true,
                    enableSnippets: false,
                    enableLiveAutocompletion: true
                });
            }

            editor.commands.bindKey("ctrl+alt+0", null);
            this.editors.push(editor);
            this.editor_for_file.set($(element).data('file-id'), editor);
            var session = editor.getSession();
            var mode = $(element).data('mode')
            session.setMode(mode);
            session.setTabSize($(element).data('indent-size'));
            session.setUseSoftTabs(true);
            session.setUseWrapMode(true);

            // set regex for parsing error traces based on the mode of the main file.
            if ($(element).parent().data('role') === "main_file") {
                this.tracepositions_regex = this.regex_for_language.get($(element).data('mode'));
            }

            /*
             * Register event handlers
             */

            // editor itself
            editor.on("paste", this.handlePasteEvent.bind(element));
            editor.on("copy", this.handleCopyEvent.bind(element));

            // listener for autosave
            session.on("change", function (editor, deltaObject, session) {
                // editor.curOp.command is empty for changes that are not caused by user input.
                // With that we can differentiate between changes caused by user input and
                // changes caused by changed text because of WebSocket notifications from a pair programming partner.
                if(_.isEmpty(editor.curOp.command)) {
                    return;
                }
                App.synchronized_editor?.editor_change(deltaObject, this.active_file);
                this.resetSaveTimer();
            }.bind(this, editor));
        }.bind(this));
    },

    handleAceThemeChangeEvent: function (event) {
        this.editors.forEach(function (editor) {
            editor.setTheme(this.THEME);
        }.bind(this));
    },

    initializeEventHandlers: function () {
        $(document).on('click', '#results a', this.showOutput.bind(this));
        $(document).on('keydown', this.handleKeyPress.bind(this));
        $(document).on('theme:change:ace', this.handleAceThemeChangeEvent.bind(this));
        $('#start_chat').on('click', function(event) {
            this.createEventHandler('pp_start_chat', null)(event)
            // Allow to open the new tab even in Safari.
            // See: https://stackoverflow.com/a/70463940
            setTimeout(() => {
                var pop_up_window = window.open($('#start_chat').data('url'), '_blank');
                if (pop_up_window) {
                    pop_up_window.onerror = function (message) {
                        $.flash.danger({text: message});
                        this.sendError(message, null);
                    };
                }
            })
        }.bind(this));
        this.initializeFileTreeButtons();
        this.initializeWorkspaceButtons();
        this.initializeRequestForComments()
    },

    teardownEventHandlers: function () {
        $(document).unbind('click');
        $(document).unbind('keydown');
        this.teardownWorkspaceButtons();
        this.teardownRequestForComments();
        const rfcModal = $('#comment-modal');
        if (rfcModal.isPresent()) {
            bootstrap.Modal.getInstance(rfcModal)?.hide();
        }
        this.teardownFileTreeButtons();
    },

    updateEditorModeToFileTypeID: function (editor, fileTypeID) {
        var newMode = 'ace/mode/text'

        $.ajax(this.fileTypeURL + '/' + fileTypeID, {
            dataType: 'json'
        }).done(function (data) {
            if (data['editor_mode'] !== null) {
                newMode = data['editor_mode'];
            }
        }).fail(_.noop)
            .always(function () {
                ace.edit(editor).session.setMode(newMode);
            });
    },

    initializeFileTree: function (own_solution = false) {
        let filesInstance;
        if (own_solution) {
            filesInstance = $('#own-files');
        } else {
            filesInstance = $('#files');
        }
        const jsTreeConfig = filesInstance.data('entries') || {core: {}};
        jsTreeConfig.core.themes = {...jsTreeConfig.core.themes, name: window.getCurrentTheme() === "dark" ? "default-dark" : "default"}
        filesInstance.jstree(jsTreeConfig);
        filesInstance.on('click', 'li.jstree-leaf > a', function (event) {
            const file_id = parseInt($(event.target).parent().attr('id'));
            const frame = $('[data-file-id="' + file_id + '"]').parent();
            this.setActiveFile(frame.data('filename'), file_id);
            this.showFrame(frame);
            this.toggleButtonStates();
        }.bind(this));

        this.installFileTreeEventHandlers(filesInstance);
    },

    installFileTreeEventHandlers: function (filesInstance) {
        // Prevent duplicate event listeners by removing them during unload.
        const themeListener = this.createFileTreeThemeChangeListener(filesInstance);
        const jsTree = filesInstance?.jstree(true);
        $(document).on('theme:change', themeListener);
        $(document).one('turbo:visit', function() {
            CodeOceanEditor.removeFileTreeEventHandlers(filesInstance);
        });
        $(window).one('beforeunload', function() {
            CodeOceanEditor.removeFileTreeEventHandlers(filesInstance);
        });
    },

    removeFileTreeEventHandlers: function (filesInstance) {
        const themeListener = this.createFileTreeThemeChangeListener(filesInstance);
        const jsTree = filesInstance?.jstree(true);
        $(document).off('theme:change', themeListener);
        if (jsTree && jsTree.element) {
            jsTree.destroy(true);
        }
    },

    createFileTreeThemeChangeListener: function (filesInstance) {
      return function (event) {
            const jsTree = filesInstance?.jstree(true);

            if (jsTree) {
                const newColorScheme = event.detail.currentTheme;
                // Update the JStree theme
                jsTree?.set_theme(newColorScheme === "dark" ? "default-dark" : "default");
            }
        }
    },

    initializeFileTreeButtons: function () {
        $('#create-file').on('click', this.showFileDialog.bind(this));
        $('#destroy-file').on('click', this.confirmDestroy.bind(this));
        $('#destroy-file-collapsed').on('click', this.confirmDestroy.bind(this));
        $('#download').on('click', this.downloadCode.bind(this));
    },

    teardownFileTreeButtons: function () {
        $('#create-file').unbind('click');
        $('#destroy-file').unbind('click');
        $('#destroy-file-collapsed').unbind('click');
        $('#download').unbind('click');
    },

    initializeSideBarCollapse: function () {
        $('#sidebar-collapse-collapsed').on('click', this.handleSideBarToggle.bind(this));
        $('#sidebar-collapse').on('click', this.handleSideBarToggle.bind(this));
        const tipButton = $('#tips-collapsed');
        if (tipButton) {
            tipButton.on('click', this.handleSideBarToggle.bind(this));
        }
        $('#sidebar').on('transitionend', this.resizeAceEditors.bind(this));
        $('#sidebar').on('transitionend', this.resizeSidebars.bind(this));
    },

    handleSideBarToggle: function () {
        const sidebar = $('#sidebar');
        sidebar.toggleClass('sidebar-col').toggleClass('sidebar-col-collapsed');
        if (sidebar.hasClass('w-25') || sidebar.hasClass('restore-to-w-25')) {
            sidebar.toggleClass('w-25').toggleClass('restore-to-w-25');
        }
        $('#sidebar-collapsed').toggleClass('d-none');
        $('#sidebar-uncollapsed').toggleClass('d-none');
    },

    initializeRegexes: function () {
        // These RegEx are run on the HTML escaped output!
        this.regex_for_language.set("ace/mode/python", /File &quot;(.+?)&quot;, line (\d+)/g);
        this.regex_for_language.set("ace/mode/java", /^(?:\.\/)?(.*\.java):(\d+):/g);
    },

    initializeWorkspaceButtons: function () {
        $('#assess').one('click', this.scoreCode.bind(this));
        $('#render').on('click', this.renderCode.bind(this));
        $('#run').one('click', this.runCode.bind(this));
        $('#stop').on('click', this.stopCode.bind(this));
        $('#test').one('click', this.testCode.bind(this));
        $('#start-over').on('click', this.confirmReset.bind(this));
        $('#start-over-active-file').on('click', this.confirmResetActiveFile.bind(this));
    },

    teardownWorkspaceButtons: function () {
        $('#assess').unbind('click');
        $('#render').unbind('click');
        $('#run').unbind('click');
        $('#stop').unbind('click');
        $('#test').unbind('click');
        $('#start-over').unbind('click');
        $('#start-over-active-file').unbind('click');
    },

    initializeRequestForComments: function () {
        var button = $('#requestComments');
        button.prop('disabled', true);
        button.on('click', function () {
            button.tooltip('hide');
            $('#rfc_intervention_text').hide()
            new bootstrap.Modal($('#comment-modal')).show();
        });

        $('#askForCommentsButton').one('click', this.requestComments.bind(this));
        $('#closeAskForCommentsButton').on('click', function () {
            bootstrap.Modal.getInstance($('#comment-modal'))?.hide();
        });

        setTimeout(function () {
            button.prop('disabled', false);
            setTimeout(function () {
                button.tooltip('show');
                setTimeout(function () {
                    button.tooltip('hide');
                }, this.REQUEST_TOOLTIP_TIME);
            }, this.REQUEST_TOOLTIP_DELAY)
        }.bind(this), this.REQUEST_FOR_COMMENTS_DELAY);
    },

    teardownRequestForComments: function () {
        $('#requestComments').unbind('click');
        $('#askForCommentsButton').unbind('click');
        $('#closeAskForCommentsButton').unbind('click');
    },

    isActiveFileRenderable: function () {
        if (this.active_frame.data() === undefined) {
            return false;
        }
        return 'renderable' in this.active_frame.data();
    },

    isActiveFileRunnable: function () {
        return this.isActiveFileExecutable() && ['main_file', 'user_defined_file', 'executable_file'].includes(this.active_frame.data('role'));
    },

    isActiveFileStoppable: function () {
        return this.isActiveFileRunnable() && this.running;
    },

    isActiveFileTestable: function () {
        return this.isActiveFileExecutable() && ['teacher_defined_test', 'user_defined_test', 'teacher_defined_linter'].includes(this.active_frame.data('role'));
    },

    populateCard: function (card, result, index) {
        card.addClass(`card border-${this.getCardClass(result)}`);
        card.find('.card-header').addClass(`bg-${this.getCardClass(result)} text-white`);
        card.find('.card-title .filename').text(result.filename);
        card.find('.card-title .number').text(index + 1);
        card.find('.row .col-md-9').eq(0).find('.number').eq(0).text(result.passed);
        card.find('.row .col-md-9').eq(0).find('.number').eq(1).text(result.count);
        if (result.weight !== 0) {
            card.find('.row .col-md-9').eq(1).find('.number').eq(0).text(parseFloat((result.score * result.weight).toFixed(2)));
            card.find('.row .col-md-9').eq(1).find('.number').eq(1).text(result.weight);
        } else {
            // Hide score row if no score could be achieved
            card.find('.attribute-row.row').eq(1).addClass('d-none');
        }
        card.find('.row .col-md-9').eq(2).html(result.message);

        // Add error message from code to card
        if (result.error_messages) {
            const targetNode = card.find('.row .col-md-9').eq(3);

            let errorMessagesToShow = [];
            result.error_messages.forEach(function (item) {
                if (item) {
                    errorMessagesToShow.push(item)
                }
            })

            // delete all current elements
            targetNode.text('');
            // create a new list and append each element
            const ul = document.createElement("ul");

            // Extract detailed linter results
            if (result.file_role === 'teacher_defined_linter') {
                const detailed_linter_results = result.detailed_linter_results;
                const severity_groups = detailed_linter_results.reduce(function(map, obj) {
                    map[obj.severity] = map[obj.severity] || []
                    map[obj.severity].push(obj);
                    return map;
                }, {});

                for (const [severity, linter_results] of Object.entries(severity_groups)) {
                    const li = document.createElement("li");
                    const text = $.parseHTML(`<u>${severity}:</u>`);
                    $(li).append(text);
                    ul.append(li);

                    const sub_ul = document.createElement("ul");
                    sub_ul.setAttribute('class', 'inline_list');
                    for (const check_run of linter_results) {
                        const sub_li = document.createElement("li");

                        let scope = '';
                        if (check_run.scope) {
                             scope = `, ${check_run.scope}()`;
                        }
                        const context = `${check_run.file_name}: ${check_run.line}${scope}`;
                        const line_link = `<a href='#' data-file='${check_run.file_name}' data-line='${check_run.line}'>${context}</a>`;
                        const message = `${check_run.name}: ${check_run.result} (${line_link})`;
                        const sub_text = $.parseHTML(message);
                        $(sub_li).append(sub_text).on("click", "a", this.jumpToSourceLine.bind(this));
                        sub_ul.append(sub_li);
                    }
                    li.append(sub_ul);
                }

            // Just show standard results for normal test results
            } else {
              errorMessagesToShow.forEach(function (item) {
                  var li = document.createElement("li");
                  var text = document.createTextNode(item);
                  $(li).append(text);
                  ul.append(li);
              })
            }

            // one or more errors?
            if (errorMessagesToShow.length > 1) {
                ul.setAttribute('class', 'inline_list');
            } else {
                ul.setAttribute('class', 'single_entry_inline_list');
            }
            targetNode.append(ul);
        }
        //card.find('.row .col-md-9').eq(4).find('a').attr('href', '#output-' + index);
    },

    createEventHandler: function (eventType, data) {
        return function (event) {
            CodeOceanEditor.publishCodeOceanEvent({
                category: eventType,
                data: data,
                exercise_id: $('#editor').data('exercise-id'),
                file_id: CodeOceanEditor.active_file.id,
            });
            event.stopPropagation();
        };
    },

    publishCodeOceanEvent: function (payload) {
        if (this.sendEvents) {
            $.ajax(this.eventURL, {
                type: 'POST',
                cache: false,
                dataType: 'JSON',
                data: {
                    event: payload
                },
                success: _.noop,
                error: _.noop
            });
        }
    },

    sendError: function (message, submission_id) {
        this.showSpinner($('#render'));
        var jqxhr = this.ajax({
            data: {
                error: {
                    message: message,
                    submission_id: submission_id
                }
            },
            url: $('#editor').data('errors-url')
        });
        jqxhr.always(this.hideSpinner);
    },

    toggleButtonStates: function () {
        $('#destroy-file').prop('disabled', this.active_frame.data('role') !== 'user_defined_file');
        $('#start-over-active-file').prop('disabled', this.active_frame.data('role') === 'user_defined_file' || this.active_frame.data('read-only') !== undefined);
        $('#dummy').toggle(!this.fileActionsAvailable());
        $('#render').toggle(this.isActiveFileRenderable());
        const runStopGroup = $('#run-stop-button-group');
        if (typeof runStopGroup.tooltip === 'function') {
            runStopGroup.tooltip('hide');
        }
        runStopGroup.toggleClass('flex-grow-1', this.isActiveFileRunnable() || this.isActiveFileStoppable());
        $('#run').toggle(this.isActiveFileRunnable() && !this.running);
        $('#stop').toggle(this.isActiveFileStoppable());
        $('#test').toggle(this.isActiveFileTestable());
    },

    jumpToSourceLine: function (event) {
        const file = $(event.target).data('file');
        const line = $(event.target).data('line');

        const frame = $('div.frame[data-filename="' + file + '"]');
        this.showFrame(frame);
        this.toggleButtonStates();

        const file_id = frame.find('.editor').data('file-id');
        this.setActiveFile(frame.data('filename'), file_id);
        this.selectFileInJsTree($('#files'), file_id);

        const editor = this.editor_for_file.get(file_id);
        editor?.gotoLine(line, 0);
        event.preventDefault();
    },

    augmentStacktraceInOutput: function () {
        if (this.tracepositions_regex) {
            $('#output > .output-element').each($.proxy(function(index, element) {
                element = $(element)

                const text = _.escape(element.text());
                element.on("click", "a", this.jumpToSourceLine.bind(this));

                let matches;

                let augmented_text = element.html();
                while (matches = this.tracepositions_regex.exec(text)) {
                    const frame = $('div.frame[data-filename="' + matches[1] + '"]')

                    if (frame.length > 0) {
                        augmented_text = augmented_text.replace(new RegExp(_.unescape(matches[0]), 'g'), "<a href='#' data-file='" + matches[1] + "' data-line='" + matches[2] + "'>" + matches[0] + "</a>");
                    }
                }
                element.html(augmented_text);
            }, this));
        }
    },

    resetOutputTab: function () {
        this.clearOutput();
        $('#flowrHint').fadeOut();
        this.clearHints();
        this.showOutputBar();
        this.clearFileDownloads();
    },

    isActiveFileBinary: function () {
        if (this.active_frame.data() === undefined) {
            return false;
        }
        return 'binary' in this.active_frame.data();
    },

    isActiveFileExecutable: function () {
        if (this.active_frame.data() === undefined) {
            return false;
        }
        return 'executable' in this.active_frame.data();
    },

    setActiveFile: function (filename, fileId) {
        this.active_file = {
            filename: filename,
            id: fileId
        };
    },

    showSpinner: function (initiator) {
        const element = $(initiator);

        if (initiator && element) {
            const tooltipElement = $(initiator).closest('[data-bs-toggle="tooltip"]');
            if (typeof tooltipElement.tooltip === 'function') {
                tooltipElement.tooltip('hide');
            }
            $(initiator).find('i.fa-solid, i.fa-regular').hide();
            $(initiator).find('i.fa-spin').addClass('d-inline-block').removeClass('d-none');
        }
    },

    showStatus: function (output) {
        switch (output.status) {
            case 'container_running':
                this.toggleButtonStates();
                break;
            case 'timeout':
            case 'buffer_overflow':
                this.showTimeoutMessage();
                break;
            case 'container_depleted':
                this.showContainerDepletedMessage();
                break;
            case 'out_of_memory':
                this.showOutOfMemoryMessage();
                break;
            case 'runner_in_use':
                this.showRunnerInUseMessage();
                break;
            case 'scoring_failure':
                this.showScoringFailureMessage();
                break;
            case 'not_for_all_users_submitted':
                this.showNotForAllUsersSubmittedMessage(output.failed_users);
                break;
            case 'scoring_too_late':
                this.showScoringTooLateMessage(output.score_sent);
                break;
            case 'exercise_finished':
                this.showExerciseFinishedMessage(output.url);
                break;
        }
    },

    clearHints: function () {
        var container = $('#error-hints');
        container.find('ul.body > li.hint').remove();
        container.fadeOut();
    },

    showHint: function (message) {
        var template = function (description, hint) {
            return '\
           <li class="hint">\
             <div class="description">\
               ' + description + '\
             </div>\
             <div class="hint">\
               ' + hint + '\
             </div>\
           </li>\
         '
        };
        var container = $('#error-hints');
        container.find('ul.body').append(template(message.description, message.hint));
        container.fadeIn();
    },

    prepareFileDownloads: function(message) {
        const fileTree = $('#download-file-tree');
        fileTree.jstree(message.data);
        fileTree.on('select_node.jstree', function (node, selected, _event) {
            selected.instance.deselect_all();
            const downloadPath = selected.node.original.download_path;
            if (downloadPath) {
                $(window).off('beforeunload');
                window.location = downloadPath;
                setTimeout(() => {
                    $(window).one('beforeunload', this.unloadEverything.bind(this, App.synchronized_editor));
                }, 250);
            }
        }.bind(this));
        $('#download-files').removeClass('d-none');
    },

    clearFileDownloads: function() {
        $('#download-files').addClass('d-none');
        $('#download-file-tree').replaceWith($('<div id="download-file-tree">'));
    },

    showContainerDepletedMessage: function () {
        $.flash.danger({
            icon: ['fa-regular', 'fa-clock'],
            text: $('#editor').data('message-depleted')
        });
    },

    showOutOfMemoryMessage: function () {
        $.flash.info({
            icon: ['fa-regular', 'fa-clock'],
            text: $('#editor').data('message-out-of-memory')
        });
    },

    showRunnerInUseMessage: function () {
        $.flash.warning({
            icon: ['fa-solid', 'fa-triangle-exclamation'],
            text: I18n.t('exercises.editor.runner_in_use')
        });
    },

    showScoringFailureMessage: function () {
        $.flash.danger({
            icon: ['fa-solid', 'fa-exclamation-circle'],
            text: I18n.t('exercises.editor.submit_failure_all')
        });
    },

    showNotForAllUsersSubmittedMessage: function (failed_users) {
        $.flash.warning({
            icon: ['fa-solid', 'fa-triangle-exclamation'],
            text: I18n.t('exercises.editor.submit_failure_other_users', {user: failed_users})
        });
    },

    showScoringTooLateMessage: function (score_sent) {
        $.flash.info({
            icon: ['fa-solid', 'fa-circle-info'],
            text: I18n.t('exercises.editor.submit_too_late', {score_sent: score_sent})
        });
    },

    showExerciseFinishedMessage: function (url) {
        $.flash.success({
            showPermanent: true,
            icon: ['fa-solid', 'fa-graduation-cap'],
            text: I18n.t('exercises.editor.exercise_finished', {url: url})
        });
    },

    showTimeoutMessage: function () {
        $.flash.info({
            icon: ['fa-regular', 'fa-clock'],
            text: $('#editor').data('message-timeout')
        });
    },

    showWebsocketError: function (error) {
        if (window.navigator.userAgent.indexOf('Edge') > -1 || window.navigator.userAgent.indexOf('Trident') > -1) {
            // Mute errors in Microsoft Edge and Internet Explorer
            return;
        }
        $.flash.danger({
            text: $('#flash').data('websocket-failure'),
            showPermanent: true
        });
        Sentry.captureException(JSON.stringify(error, ["message", "arguments", "type", "name", "data"]));
    },

    showFileDialog: async function (event) {
        event.preventDefault();

        const submission = await this.createSubmission('#create-file', null).catch(this.ajaxError.bind(this));
        if (!submission) return;

        $('#code_ocean_file_context_id').val(submission.id);
        new bootstrap.Modal($('#modal-file')).show();
    },

    initializeOutputBarToggle: function () {
        $('#toggle-sidebar-output').on('click', this.hideOutputBar.bind(this));
        $('#toggle-sidebar-output-collapsed').on('click', this.showOutputBar.bind(this));
        $('#output_sidebar').on('transitionend', this.resizeAceEditors.bind(this));
        $('#output_sidebar').on('transitionend', this.resizeSidebars.bind(this));
    },

    showOutputBar: function () {
        $('#output_sidebar_collapsed').addClass('d-none');
        $('#output_sidebar_uncollapsed').removeClass('d-none');
        $('#output_sidebar').removeClass('output-col-collapsed').addClass('output-col');
    },

    hideOutputBar: function () {
        $('#output_sidebar_collapsed').removeClass('d-none');
        $('#output_sidebar_uncollapsed').addClass('d-none');
        $('#output_sidebar').removeClass('output-col').addClass('output-col-collapsed');
    },

    initializeDescriptionToggle: function () {
        $('#exercise-headline').on('click', this.toggleDescriptionCard.bind(this));
        $('a#toggle').on('click', this.toggleDescriptionCard.bind(this));
    },

    toggleDescriptionCard: function (event) {
        $('#description-card').toggleClass('description-card-collapsed').toggleClass('description-card');
        $('#description-symbol').toggleClass('fa-chevron-down').toggleClass('fa-chevron-right');
        var toggle = $('a#toggle');
        toggle.text(toggle.text() == toggle.data('hide') ? toggle.data('show') : toggle.data('hide'));
        this.resizeAceEditors();
        this.resizeSidebars();
        event.preventDefault();
    },

    /**
     * interventions
     * */
    initializeInterventionTimer: function () {
        const editor = $('#editor');

        if (editor.data('rfc-interventions') || editor.data('break-interventions') || editor.data('tips-interventions')) { // split in break or rfc intervention
            window.onblur = function () {
                window.blurred = true;
            };
            window.onfocus = function () {
                window.blurred = false;
            };

            const delta = 100; // time in ms to wait for window event before time gets stopped
            let tid;
            $.ajax({
                dataType: 'json',
                method: 'GET',
                // get working times for this exercise
                url: editor.data('working-times-url'),
                success: function (data) {
                    const percentile75 = data['working_time_75_percentile'];
                    const accumulatedWorkTimeUser = data['working_time_accumulated'];

                    let minTimeIntervention = 20 * 60 * 1000;

                    let timeUntilIntervention;
                    if ((accumulatedWorkTimeUser - percentile75) > 0) {
                        // working time is already over 75 percentile
                        timeUntilIntervention = minTimeIntervention;
                    } else {
                        // working time is less than 75 percentile
                        // ensure we give user at least minTimeIntervention before we bother the user
                        timeUntilIntervention = Math.max(percentile75 - accumulatedWorkTimeUser, minTimeIntervention);
                    }

                    tid = setInterval(function () {
                        if (window.blurred) {
                            return;
                        }
                        timeUntilIntervention -= delta;
                        if (timeUntilIntervention <= 0) {
                            const interventionSaveUrl = editor.data('intervention-save-url');
                            clearInterval(tid);
                            // timeUntilIntervention passed
                            if (editor.data('tips-interventions')) {
                                const modal = $('#tips-intervention-modal');
                                if (!modal.isPresent()) {
                                    // The modal is not present (e.g., because the site was navigated), so we don't continue here.
                                    return;
                                }

                                modal.find('.modal-footer').html(I18n.t("exercises.implement.intervention.explanation", {duration: Math.round(percentile75 / 60)}));
                                new bootstrap.Modal(modal).show();
                                $.ajax({
                                    data: {
                                        intervention_type: 'TipsIntervention'
                                    },
                                    dataType: 'json',
                                    type: 'POST',
                                    url: interventionSaveUrl
                                });
                            } else if (editor.data('break-interventions')) {
                                const modal = $('#break-intervention-modal');
                                if (!modal.isPresent()) {
                                    // The modal is not present (e.g., because the site was navigated), so we don't continue here.
                                    return;
                                }

                                modal.find('.modal-footer').html(I18n.t("exercises.implement.intervention.explanation", {duration: Math.round(percentile75 / 60)}));
                                new bootstrap.Modal(modal).show();
                                $.ajax({
                                    data: {
                                        intervention_type: 'BreakIntervention'
                                    },
                                    dataType: 'json',
                                    type: 'POST',
                                    url: interventionSaveUrl
                                });
                            } else if (editor.data('rfc-interventions')) {
                                const button = $('#requestComments');
                                // only show intervention if user did not requested for a comment already
                                if (!button.prop('disabled')) {
                                    $('#rfc_intervention_text').show();
                                    const modal = $('#comment-modal');
                                    if (!modal.isPresent()) {
                                        // The modal is not present (e.g., because the site was navigated), so we don't continue here.
                                        return;
                                    }

                                    modal.find('.modal-footer').html(I18n.t("exercises.implement.intervention.explanation", {duration: Math.round(percentile75 / 60)}));
                                    modal.on('hidden.bs.modal', function () {
                                        modal.find('.modal-footer').text('');
                                    });
                                    new bootstrap.Modal(modal).show();
                                    $.ajax({
                                        data: {
                                            intervention_type: 'QuestionIntervention'
                                        },
                                        dataType: 'json',
                                        type: 'POST',
                                        url: interventionSaveUrl
                                    });
                                }
                            }
                        }
                    }, delta);
                }
            });
        }
    },

    applyChanges: function (delta, active_file) {
        const editor = this.editor_for_file?.get(active_file.id);
        if (editor === undefined) {
            return;
        }
        editor.session.doc.applyDeltas([delta]);
    },

    showPartnersConnectionStatus: function (status, username) {
        switch(status) {
            case 'connected':
                $('#pg_session').text(I18n.t('exercises.editor.is_online', {name: username}));
                break;
            case 'disconnected':
                $('#pg_session').text(I18n.t('exercises.editor.is_offline', {name: username}));
                break;
        }
    },

    initializeEverything: function () {
        CodeOceanEditor.sendEvents = $('#editor').data('events-enabled');
        CodeOceanEditor.editors = [];
        this.initializeRegexes();
        this.initializeEditors();
        this.initializeEventHandlers();
        this.initializeFileTree();
        this.initializeSideBarCollapse();
        this.initializeOutputBarToggle();
        this.initializeDescriptionToggle();
        this.initializeInterventionTimer();
        this.initPrompt();
        this.renderScore();
        this.showFirstFile();
        this.resizeAceEditors();
        this.resizeSidebars();
        this.initializeDeadlines();
        CodeOceanEditorTips.initializeEventHandlers();

        $(document).one("turbo:visit", this.unloadEverything.bind(this, App.synchronized_editor));
        $(window).one("beforeunload", this.unloadEverything.bind(this, App.synchronized_editor));

        // create autosave when the editor is opened the first time
        this.autosave();
    },

    unloadEverything: function () {
        App.synchronized_editor?.disconnect();
        this.autosaveIfChanged();
        this.unloadEditor();
        this.teardownEventHandlers();
    },

    unloadEditor: function () {
        $(document).off('theme:change:ace');
        CodeOceanEditor.cacheEditorContent();
        CodeOceanEditor.destroyEditors();
    },

    cacheEditorContent: function () {
        // Persist the content of the editors in a hidden textarea to enable Turbo caching.
        // In this case, we iterate over _all_ editors, not just writable ones.
        for (const [file_id, editor] of this.editor_for_file) {
            const file_content = editor.getValue().replace(/\r\n/g, '\n');
            const editorContent = $(`.editor-content[data-file-id='${file_id}']`);
            editorContent.text(file_content);
        }
    },

    destroyEditors: function () {
        CodeOceanEditor.editors.forEach(editor => editor.destroy());
        CodeOceanEditor.editors = [];
    }
};
