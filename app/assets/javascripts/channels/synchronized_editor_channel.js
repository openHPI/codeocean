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
          if (current_user_id !== data['current_user_id']) {
            CodeOceanEditor.applyChanges(data['delta']['data']);
          }
        },

        send_changes(delta) {
          const delta_with_user_id = {current_user_id: current_user_id, delta: delta}
          this.perform('send_changes', {delta_with_user_id: delta_with_user_id});
        }
      });
    }
  }
});
