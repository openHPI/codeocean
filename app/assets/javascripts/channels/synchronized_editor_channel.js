$(document).on('turbolinks:load', function () {

  if (window.location.pathname.includes('/implement')) {
    const editor = $('#editor');
    const exercise_id = editor.data('exercise-id');
    const current_user_id = editor.data('user-id');
    const current_contributor_id = editor.data('contributor-id');

    if ($.isController('exercises') && current_user_id !== current_contributor_id) {

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
          if (current_user_id !== data.current_user_id) {
            switch(data.command) {
              case 'editor_change':
                CodeOceanEditor.applyChanges(data.delta.data, data.active_file);
                break;
              case 'connection_change':
                CodeOceanEditor.showPartnersConnectionStatus(data.status, data.current_user_name);
                this.perform('send_hello');
                break;
              case 'hello':
                CodeOceanEditor.showPartnersConnectionStatus(data.status, data.current_user_name);
                break;
            }
          }
        },

        send_changes(delta, active_file) {
          const delta_with_user_id = {command: 'editor_change', current_user_id: current_user_id, active_file: active_file, delta: delta}
          this.perform('send_changes', {delta_with_user_id: delta_with_user_id});
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
