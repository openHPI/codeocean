$(document).on('turbolinks:load', function () {
    const exerciseCaption = $('#exercise_caption');

    if (!$.isController('request_for_comments') || !exerciseCaption.isPresent()) {
        return;
    }

    $('.modal-content').draggable({
        handle: '.modal-header'
    }).resizable({
        autoHide: true
    });

    const solvedButton = $('#mark-as-solved-button');
    const thankYouContainer = $('#thank-you-container');
    const rfcId = exerciseCaption.data('rfc-id');

    solvedButton.on('click', function () {
        $.ajax({
            dataType: 'json',
            method: 'GET',
            url: Routes.mark_as_solved_request_for_comment_path(rfcId),
        }).done(function (response) {
            if (response.solved) {
                solvedButton.removeClass('btn-primary');
                solvedButton.addClass('btn-success');
                solvedButton.html(I18n.t('request_for_comments.solved'));
                solvedButton.off('click');
                thankYouContainer.show();
            }
        });
    });

    $('#send-thank-you-note').on('click', function () {
        const value = $('#thank-you-note').val();
        if (value) {
            $.ajax({
                dataType: 'json',
                method: 'POST',
                url: Routes.set_thank_you_note_request_for_comment_path(rfcId),
                data: {
                    note: value
                }
            }).done(function () {
                thankYouContainer.hide();
            });
        }
    });

    $('#cancel-thank-you-note').on('click', function () {
        thankYouContainer.hide();
    });

    $('.text > .collapse-button').on('click', function (_event) {
        $(this).toggleClass('fa-chevron-down');
        $(this).toggleClass('fa-chevron-up');
        $(this).parent().toggleClass('collapsed');
    });

// set file paths for ace
    _.each(['modePath', 'themePath', 'workerPath'], function (attribute) {
        ace.config.set(attribute, CodeOceanEditor.ACE_FILES_PATH);
    });

    const commentitor = $('.editor');

    commentitor.each(function (index, editor) {
        const currentEditor = ace.edit(editor);
        currentEditor.setReadOnly(true);
        // set editor mode (used for syntax highlighting
        currentEditor.getSession().setMode($(editor).data('mode'));
        currentEditor.getSession().setOption("useWorker", false);

        currentEditor.commentVisualsByLine = {};
        setAnnotations(currentEditor, $(editor).data('file-id'));
        currentEditor.on("guttermousedown", handleSidebarClick);
        currentEditor.on("guttermousemove", showPopover);
    });

    function preprocess(commentText) {
        // sanitize comments to deal with XSS attacks:
        commentText = $('div.sanitizer').text(commentText).html();
        // display original line breaks:
        return commentText.replace(/\n/g, '<br>');
    }

    function replaceNewlineTags(commentText) {
        // display original line breaks as \n:
        return commentText.replace(/<br>/g, '\n');
    }

    function generateCommentHtmlContent(comments) {
        let htmlContent = '';
        comments.forEach(function (comment, index) {
            const commentText = preprocess(comment.text);
            if (index !== 0) {
                htmlContent += '<div class="comment-divider"></div>'
            }
            htmlContent += '\
        <div class="comment" data-comment-id=' + comment.id + '> \
          <div class="comment-header"> \
            <div class="comment-username">' + preprocess(comment.username) + '</div> \
            <div class="comment-date">' + comment.date + '</div> \
            <div class="comment-updated' + (comment.updated ? '' : ' d-none') + '"> \
              <i class="fa-solid fa-pencil" aria-hidden="true"></i> \
              ' + I18n.t('request_for_comments.comment_edited') + ' \
            </div> \
          </div> \
          <div class="comment-content">' + commentText + '</div> \
          <textarea class="comment-editor">' + commentText + '</textarea> \
          <div class="comment-actions' + (comment.editable ? '' : ' d-none') + '"> \
            <button class="action-edit btn btn-sm btn-warning">' + I18n.t('shared.edit') + '</button> \
            <button class="action-delete btn btn-sm btn-danger">' + I18n.t('shared.destroy') + '</button> \
          </div> \
        </div>';
        });
        return htmlContent;
    }

    function buildPopover(comments, where) {
        // only display the newest three comments in preview
        const maxComments = 3;
        let htmlContent = generateCommentHtmlContent(comments.reverse().slice(0, maxComments));
        if (comments.length > maxComments) {
            // add a hint that there are more comments than shown here
            htmlContent += '<div class="popover-footer">' +
                I18n.t('request_for_comments.click_for_more_comments', {numComments: comments.length - maxComments}) +
                '</div>';
        }
        where.popover({
            content: htmlContent,
            html: true, // necessary to style comments. XSS is not possible due to comment pre-processing (sanitizing)
            trigger: 'manual', // can only be triggered by $(where).popover('show' | 'hide')
            container: 'body'
        });
    }

    function setAnnotations(editor, fileid) {
        const session = editor.getSession();

        const jqrequest = $.ajax({
            dataType: 'json',
            method: 'GET',
            url: Routes.comments_path(),
            data: {
                file_id: fileid
            }
        });

        jqrequest.done(function (response) {
            $.each(response, function (index, comment) {
                comment.className = 'code-ocean_comment';
            });
            session.setAnnotations(response);
        });
    }

    function getCommentsForRow(editor, row) {
        return editor.getSession().getAnnotations().filter(function (element) {
            return element.row === row;
        })
    }

    function deleteComment(commentId, editor, file_id, callback) {
        const jqxhr = $.ajax({
            type: 'DELETE',
            url: Routes.comment_path(commentId)
        });
        jqxhr.done(function () {
            setAnnotations(editor, file_id);
            callback();
        });
        jqxhr.fail(ajaxError);
    }

    function updateComment(commentId, text, editor, file_id, callback) {
        const jqxhr = $.ajax({
            type: 'PATCH',
            url: Routes.comment_path(commentId),
            data: {
                comment: {
                    text: text
                }
            }
        });
        jqxhr.done(function () {
            setAnnotations(editor, file_id);
            callback();
        });
        jqxhr.fail(ajaxError);
    }

    function createComment(file_id, row, editor, commenttext) {
        const jqxhr = $.ajax({
            data: {
                comment: {
                    file_id: file_id,
                    row: row,
                    column: 0,
                    text: commenttext,
                    request_id: $('h4#exercise_caption').data('rfc-id')
                }
            },
            dataType: 'json',
            method: 'POST',
            url: Routes.comments_path()
        });
        jqxhr.done(function () {
            setAnnotations(editor, file_id);
        });
        jqxhr.fail(ajaxError);
    }

    function subscribeToRFC(subscriptionType, checkbox) {
        checkbox.attr("disabled", true);
        const jqxhr = $.ajax({
            data: {
                subscription: {
                    request_for_comment_id: $('h4#exercise_caption').data('rfc-id'),
                    subscription_type: subscriptionType
                }
            },
            dataType: 'json',
            method: 'POST',
            url: Routes.subscriptions_path({format: 'json'})
        });
        jqxhr.done(function (subscription) {
            checkbox.data('subscription', subscription.id);
            checkbox.attr("disabled", false);
        });
        jqxhr.fail(function (response) {
            checkbox.prop('checked', false);
            checkbox.attr("disabled", false);
            ajaxError(response);
        });
    }

    function unsubscribeFromRFC(checkbox) {
        checkbox.attr("disabled", true);
        const subscriptionId = checkbox.data('subscription');
        const jqxhr = $.ajax({
            url: Routes.unsubscribe_subscription_path(subscriptionId, {format: 'json'})
        });
        jqxhr.done(function (response) {
            checkbox.prop('checked', false);
            checkbox.data('subscription', null);
            checkbox.attr("disabled", false);
            $.flash.success({text: response.message});
        });
        jqxhr.fail(function (response) {
            checkbox.prop('checked', true);
            checkbox.attr("disabled", false);
            ajaxError(response);
        });
    }

    let lastRow = null;
    let lastTarget = null;

    function showPopover(e) {
        const target = e.domEvent.target;
        const row = e.getDocumentPosition().row;

        if (target.className.indexOf('ace_gutter-cell') === -1 || lastRow === row) {
            return;
        }
        if (lastTarget === target) {
            // sometimes the row gets updated before the DOM event target, so we need to wait for it to change
            return;
        }
        lastRow = row;

        const editor = e.editor;
        const comments = getCommentsForRow(editor, row);
        buildPopover(comments, $(target));
        lastTarget = target;

        $(target).popover('show');
        $(target).on('mouseleave', function () {
            $(this).off('mouseleave');
            $(this).popover('dispose');
        });
    }

    $('.ace_gutter').on('mouseleave', function () {
        lastRow = null;
        lastTarget = null;
    });

    function handleSidebarClick(e) {
        const target = e.domEvent.target;
        if (target.className.indexOf('ace_gutter-cell') === -1) return;

        const editor = e.editor;
        const fileid = $(editor.container).data('file-id');

        const row = e.getDocumentPosition().row;
        e.stop();
        $('.modal-title').text(I18n.t('request_for_comments.modal_title', {line: row + 1}));

        const commentModal = $('#comment-modal');

        const otherComments = commentModal.find('#otherComments');
        const htmlContent = generateCommentHtmlContent(getCommentsForRow(editor, row));
        if (htmlContent) {
            otherComments.show();
            const container = otherComments.find('.container');
            container.html(htmlContent);

            const deleteButtons = container.find('.action-delete');
            deleteButtons.on('click', function (event) {
                const button = $(event.target);
                const parent = $(button).parent().parent();
                const commentId = parent.data('comment-id');

                deleteComment(commentId, editor, fileid, function () {
                    parent.html('<div class="comment-removed">' + I18n.t('comments.deleted') + '</div>');
                });
            });

            const editButtons = container.find('.action-edit');
            editButtons.on('click', function (event) {
                const button = $(event.target);
                const parent = $(button).parent().parent();
                const commentId = parent.data('comment-id');
                const currentlyEditing = button.data('editing');

                const deleteButton = parent.find('.action-delete');
                const commentContent = parent.find('.comment-content');
                const commentEditor = parent.find('textarea.comment-editor');
                const commentUpdated = parent.find('.comment-updated');

                if (currentlyEditing) {
                    updateComment(commentId, commentEditor.val(), editor, fileid, function () {
                        button.text(I18n.t('shared.edit'));
                        button.data('editing', false);
                        commentContent.html(preprocess(commentEditor.val()));
                        deleteButton.show();
                        commentContent.show();
                        commentEditor.hide();
                        commentUpdated.removeClass('d-none');
                    });
                } else {
                    button.text(I18n.t('comments.save_update'));
                    button.data('editing', true);
                    deleteButton.hide();
                    commentContent.hide();
                    commentEditor.val(replaceNewlineTags(commentEditor.val()));
                    commentEditor.show();
                }
            });
        } else {
            otherComments.hide();
        }

        const subscribeCheckbox = commentModal.find('#subscribe');
        subscribeCheckbox.prop('checked', subscribeCheckbox.data('subscription'));
        subscribeCheckbox.off('change');
        subscribeCheckbox.on('change', function () {
            if (this.checked) {
                subscribeToRFC('author', $(this));
            } else {
                unsubscribeFromRFC($(this));
            }
        });

        const addCommentButton = commentModal.find('#addCommentButton');
        addCommentButton.off('click');
        addCommentButton.on('click', function () {
            const commentTextarea = commentModal.find('#myComment > textarea');
            const commenttext = commentTextarea.val();
            if (commenttext !== "") {
                createComment(fileid, row, editor, commenttext);
                commentTextarea.val('');
                bootstrap.Modal.getInstance(commentModal).hide();
            }
        });

        new bootstrap.Modal(commentModal).show();
    }

    function ajaxError(response) {
        const responseJSON = ((response || {}).responseJSON || {});
        const message = responseJSON.message || responseJSON.error || '';

        $.flash.danger({
            text: message.length > 0 ? message : $('#flash').data('message-failure'),
            showPermanent: response.status === 422,
        });
    }
});
