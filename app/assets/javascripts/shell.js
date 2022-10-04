$(document).on('turbolinks:load', function () {
    const ENTER_KEY_CODE = 13;

    const clearOutput = function () {
        log.html('');
    };

    const executeCommand = function (command) {
        $.ajax({
            data: {
                command: command,
                sudo: sudo.is(':checked')
            },
            method: 'POST',
            url: Routes.execute_command_execution_environment_path(id)
        }).done(handleResponse);
    };

    const handleKeyPress = function (event) {
        if (event.which === ENTER_KEY_CODE) {
            const command = $(this).val();
            if (command === 'clear') {
                clearOutput();
            } else {
                printCommand(command);
                executeCommand(command);
            }
            $(this).val('');
        }
    };

    const handleResponse = function (response) {
        // Always print stdout and stderr
        printOutput(response);

        // If an error occurred, print it too
        if (response.status === 'timeout') {
            printTimeout(response);
        } else if (response.status === 'out_of_memory') {
            printOutOfMemory(response);
        }
    };

    const printCommand = function (command) {
        const em = $('<em>');
        em.text(command);
        const p = $('<p>');
        p.append(em)
        log.append(p);
    };

    const printOutput = function (output) {
        if (output) {
            if (output.stdout) {
                const element = $('<p>');
                element.addClass('text-success');
                element.text(output.stdout);
                log.append(element);
            }

            if (output.stderr) {
                const element = $('<p>');
                element.addClass('text-warning');
                element.text(output.stderr);
                log.append(element);
            }

            if (!output.stdout && !output.stderr) {
                const element = $('<p>');
                element.addClass('text-muted');
                element.text(log.data('message-no-output'));
                log.append(element);
            }
        }
    };

    const printTimeout = function (output) {
        const element = $('<p>');
        element.addClass('text-danger');
        element.text($('#shell').data('message-timeout'));
        log.append(element);
    };

    const printOutOfMemory = function (output) {
        const element = $('<p>');
        element.addClass('text-danger');
        element.text($('#shell').data('message-out-of-memory'));
        log.append(element);
    };

    const retrieveFiles = function () {
        let fileTree = $('#download-file-tree');

        // Get current instance of the jstree if available and refresh the existing one.
        // Otherwise, initialize a new one.
        if (fileTree.jstree(true)) {
            return fileTree.jstree('refresh');
        } else {
            fileTree.removeClass('my-3 justify-content-center');
            fileTree.jstree({
                'core': {
                    'data': {
                        'url': function (node) {
                            const params = {sudo: sudo.is(':checked')};
                            return Routes.list_files_in_execution_environment_path(id, params);
                        },
                        'data': function (node) {
                            return {'path': getPath(fileTree.jstree(), node)|| '/'};
                        }
                    }
                }
            });
            fileTree.on('select_node.jstree', function (node, selected, _event) {
                // We never want a node to be selected permanently, so we deselect it immediately.
                selected.instance.deselect_all();

                const path = getPath(selected.instance, selected.node)
                const params = {sudo: sudo.is(':checked')};
                const downloadPath = Routes.download_file_from_execution_environment_path(id, path, params);

                // Now we download the file if allowed.
                if (selected.node.original.icon.split(" ").some(function (icon) {
                    return ['fa-lock', 'fa-folder'].includes(icon);
                })) {
                    $.flash.danger({
                        icon: ['fa-solid', 'fa-shield-halved'],
                        text: I18n.t('execution_environments.shell.file_tree.permission_denied')
                    });
                } else {
                    window.location = downloadPath;
                }
            }.bind(this));
        }
    }

    const getPath = function (jstree, node) {
        if (node.id === '#') {
            // Root node
            return '/'
        }

        // We build the path to the file by concatenating the paths of all parent nodes.
        let file_path = node.parents.reverse().map(function (id) {
            return jstree.get_text(id);
        }).filter(function (text) {
            return text !== false;
        }).join('/');

        return `${node.parent !== '#' ? '/' : ''}${file_path}${node.original.path}`;
    }

    const shell = $('#shell');

    if (!shell.isPresent()) {
        return;
    }

    const command = $('#command')
    command.focus();
    command.on('keypress', handleKeyPress);

    const id = shell.data('id');
    const log = $('#output');

    const sudo = $('#sudo');
    sudo.on('change', function () {
        sudo.parent().toggleClass('text-muted')
        command.focus();
    });
    $('#reload-files').on('click', function () {
        new bootstrap.Collapse('#collapse_files', 'show');
        retrieveFiles();
    });
    $('#reload-now-link').on('click', retrieveFiles);
})
;
