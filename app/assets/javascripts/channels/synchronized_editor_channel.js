$(document).on('turbolinks:load', function () {

  if (window.location.pathname.includes('/implement')) {
    function generateUUID() {
      // We decided to use this function instead of crypto.randomUUID() because it also supports older browser versions
      // https://caniuse.com/?search=createObjectURL
      return URL.createObjectURL(new Blob()).slice(-36)
    }

    function is_other_user(user) {
      return !_.isEqual(current_user, user);
    }

    function is_other_session(other_session_id) {
      return session_id !== other_session_id;
    }

    const editor = $('#editor');
    const exercise_id = editor.data('exercise-id');
    const session_id = generateUUID();

    if ($.isController('exercises') && is_other_user(current_contributor)) {

      App.synchronized_editor = App.cable.subscriptions.create({
        channel: "SynchronizedEditorChannel", exercise_id: exercise_id
      }, {


        connected() {
          // Called when the subscription is ready for use on the server
        },

        disconnected() {
          // Called when the subscription has been terminated by the server
        },

        received(data) {
          // Called when there's incoming data on the websocket for this channel
          switch (data.action) {
            case 'editor_change':
              if (is_other_session(data.session_id)) {
                CodeOceanEditor.applyChanges(data.delta, data.active_file);
              }
              break;
            case 'connection_change':
              if (is_other_user(data.user)) {
                CodeOceanEditor.showPartnersConnectionStatus(data.status, data.user.displayname);
                this.perform('connection_status');
              }
              // If a user has multiple open windows and closes one of them,
              // the other group members will show that the user is offline.
              // Therefore, we check if the person is still connected with another open window.
              // Then, the user sends again their connection status.
              else if (data.status === 'disconnected') {
                  this.perform('connection_status');
              }
              break;
            case 'connection_status':
              if (is_other_user(data.user)) {
                CodeOceanEditor.showPartnersConnectionStatus(data.status, data.user.displayname);
              }
              break;
          }
        },

        editor_change(delta, active_file) {
          const message = {session_id: session_id, active_file: active_file, delta: delta.data}
          this.perform('editor_change', message);
        },

        is_connected() {
          return App.cable.subscriptions.findAll(App.synchronized_editor.identifier).length > 0
        },

        disconnect() {
          if (this.is_connected()) {
            this.unsubscribe();
          }
        }
      });
    }
  }
});
