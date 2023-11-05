$(document).on('turbolinks:load', function () {

  if (window.location.pathname.includes('/implement')) {
    var editor = $('#editor');
    var exercise_id = editor.data('exercise-id');

    if ($.isController('exercises') && ProgrammingGroups.is_other_user(current_contributor)) {

      App.synchronized_editor = App.cable.subscriptions.create({
        channel: "SynchronizedEditorChannel", exercise_id: exercise_id
      }, {
        connected() {
          // Called when the subscription is ready for use on the server
        },

        disconnected() {
          // Called when the subscription has been terminated by the server
          alert(I18n.t('programming_groups.implement.info_disconnected'));
        },

        received(data) {
          // Called when there's incoming data on the websocket for this channel
          switch (data.action) {
            case 'session_id':
              ProgrammingGroups.session_id = data.session_id;
              break;
            case 'editor_change':
              if (ProgrammingGroups.is_other_session(data.session_id)) {
                CodeOceanEditor.applyChanges(data.delta, data.active_file);
              }
              break;
            case 'connection_change':
              if (ProgrammingGroups.is_other_session(data.session_id) && data.status === 'connected') {
                const message = {files: CodeOceanEditor.collectFiles(), session_id: ProgrammingGroups.session_id};
                this.perform('current_content', message);
              }
              if (ProgrammingGroups.is_other_user(data.user)) {
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
              if (ProgrammingGroups.is_other_user(data.user)) {
                CodeOceanEditor.showPartnersConnectionStatus(data.status, data.user.displayname);
              }
              break;
            case 'current_content':
            case 'reset_content':
              if (ProgrammingGroups.is_other_session(data.session_id)) {
                CodeOceanEditor.setEditorContent(data);
              }
              break;
          }
        },

        reset_content(content) {
          this.perform('reset_content', content);
        },

        editor_change(delta, active_file) {
          const message = {session_id: ProgrammingGroups.session_id, active_file: active_file, delta: delta}
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
