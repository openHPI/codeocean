CodeOceanEditorPrompt = {
    prompt: '#prompt',

    showPrompt: function(msg) {
        var label = $('#prompt .input-group-text');
        var prompt = $(this.prompt);
        label.text(msg.data || label.data('prompt'));
        if (prompt.isPresent() && prompt.hasClass('d-none')) {
            prompt.removeClass('d-none');
        }
        $('#prompt input').focus();
    },

    hidePrompt: function() {
        var prompt = $(this.prompt);
        if (prompt.isPresent() && !prompt.hasClass('d-none')) {
            prompt.addClass('d-none');
        }
    },

    initPrompt: function() {
        if ($('#run').isPresent()) {
            $('#run').bind('click', this.hidePrompt.bind(this));
        }
        if ($('#prompt').isPresent()) {
            $('#prompt').on('keypress', this.handlePromptKeyPress.bind(this));
            $('#prompt-submit').on('click', this.submitPromptInput.bind(this));
        }
    },

    submitPromptInput: function() {
        var input = $('#prompt-input');
        var message = input.val();
        this.websocket.send(JSON.stringify({cmd: 'result', 'data': message}));
        this.websocket.flush();
        input.val('');
        this.hidePrompt();
    },

    handlePromptKeyPress: function(evt) {
        if (evt.which === this.ENTER_KEY_CODE) {
            this.submitPromptInput();
        }
    }
};