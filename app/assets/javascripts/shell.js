$(document).on('turbolinks:load', function () {
    const ENTER_KEY_CODE = 13;

    const clearOutput = function () {
        $('#output').html('');
    };

    const executeCommand = function (command) {
        $.ajax({
            data: {
                command: command,
                sudo: $('#sudo').is(':checked')
            },
            method: 'POST',
            url: $('#shell').data('url')
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
        $('#output').append(p);
    };

    const printOutput = function (output) {
        if (output) {
            if (output.stdout) {
                const element = $('<p>');
                element.addClass('text-success');
                element.text(output.stdout);
                $('#output').append(element);
            }

            if (output.stderr) {
                const element = $('<p>');
                element.addClass('text-warning');
                element.text(output.stderr);
                $('#output').append(element);
            }

            if (!output.stdout && !output.stderr) {
                const element = $('<p>');
                element.addClass('text-muted');
                const output = $('#output');
                element.text(output.data('message-no-output'));
                output.append(element);
            }
        }
    };

    const printTimeout = function (output) {
        const element = $('<p>');
        element.addClass('text-danger');
        element.text($('#shell').data('message-timeout'));
        $('#output').append(element);
    };

    const printOutOfMemory = function (output) {
        const element = $('<p>');
        element.addClass('text-danger');
        element.text($('#shell').data('message-out-of-memory'));
        $('#output').append(element);
    };

    if ($('#shell').isPresent()) {
        const command = $('#command')
        command.focus();
        command.on('keypress', handleKeyPress);

        const sudo = $('#sudo');
        sudo.on('change', function () {
            sudo.parent().toggleClass('text-muted')
            command.focus();
        });
    }
})
;
