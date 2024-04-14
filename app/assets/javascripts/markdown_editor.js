/**
 * ToastUi editor initializer
 *
 * This script transforms form textareas created with
 * "MarkdownFormBuilder" into ToastUi markdown editors.
 *
 */

const BACKTICK = 192;
// These counters can be global. Scoping them to each editor becomes redundant
// since they are reset to this state when switching editors.
// Read more: https://github.com/openHPI/codeocean/pull/2242#discussion_r1576617432
let backtickPressedCount = 0;
let justInsertedCodeBlock = false;

const deleteSelection = (editor, count) => {
  // The backtick is a so-called dead key, which is waiting for further input to be combined with.
  // For example a backtick and the letter a are combined to à.
  // When we remove a selection ending with a backtick, we want to clear the keyboard buffer, too.
  // This ensures that typing a regular character a after this operation is not combined into à, but just inserted as a.
  // This solution is taken from https://stackoverflow.com/a/72634132.
  editor.blur();
  setTimeout(() => editor.focus());
  // Get current position
  const selectionRange = editor.getSelection();
  // Replace the previous `count` characters with an empty string.
  // We use a replace function (rather than delete) to avoid issues with line breaks in ToastUi.
  // Otherwise, a line break following the cursor position might still be displayed normally,
  // but could be removed erroneously from the internal editor state.
  // If this happens, code blocks ending with \n``` are not recognized correctly.
  editor.replaceSelection(
    "",
    [selectionRange[0][0], selectionRange[0][1] - count],
    [selectionRange[1][0], selectionRange[1][1]]
  );
};
const resetCount = (withBlock = false) => {
  backtickPressedCount = 0;
  justInsertedCodeBlock = withBlock;
};

const initializeMarkdownEditors = () => {
  const editors = document.querySelectorAll(
    '[data-behavior="markdown-editor-widget"]'
  );

  editors.forEach((editor) => {
    const formInput = document.querySelector(`#${editor.dataset.id}`);
    if (!editor || !formInput) return;

    const toastEditor = new ToastUi({
      el: editor,
      theme: window.getCurrentTheme(),
      initialValue: formInput.value,
      placeholder: formInput.placeholder,
      extendedAutolinks: true,
      linkAttributes: {
        target: "_blank",
      },
      previewHighlight: false,
      height: "300px",
      autofocus: false,
      usageStatistics: false,
      language: I18n.locale,
      toolbarItems: [
        ["heading", "bold", "italic"],
        ["link", "quote", "code", "codeblock"],
        ["image"],
        ["ul", "ol"],
      ],
      initialEditType: "markdown",
      events: {
        change: () => {
          // Keep real form <textarea> in sync
          const content = toastEditor.getMarkdown();
          formInput.value = content;
        },
        // Fix ToastUI editor bug preventing manual codeblock insertion:
        // Manually inserting a codeblock adding three backticks and hitting enter
        // is not functioning in the ToastUI editor due to an existing bug in the library.
        // Therefore, this `keyup` handler implements a workaround to address the issue.
        keyup: (_, event) => {
          // Although the use of keyCode seems to be deprecated, the suggested alternatives (key or code)
          // work inconsistently across browsers. Using keyCode works flawless for now.
          // Read more: https://github.com/openHPI/codeocean/pull/2242#discussion_r1576675620
          if (event.keyCode === BACKTICK) {
            backtickPressedCount++;
            if (backtickPressedCount === 2) {
              // Remove the last two backticks and insert a code block
              // The order of operations is important here: Inserting the code block first and then removing
              // some backticks won't work, since this would infer with the internal ToastUi editor state.
              // With the current solution, we don't mingle with the code block inserted by ToastUi at all.
              deleteSelection(toastEditor, 2);
              toastEditor.exec("codeBlock");
              resetCount(true);
            }
          } else if (backtickPressedCount === 1 && justInsertedCodeBlock) {
            // We want to improve the usage of our code block fix with the following mechanism.
            // Usually, three backticks are required to start a code block.
            // However, with our workaround only two backticks are required.
            // Out of habit, however, users might still enter three backticks at once,
            // not noticing that the code block was already inserted after the second one.
            // Thus, we remove one additional backtick entered after starting a code block through our fix.
            deleteSelection(toastEditor, 1);
            resetCount();
          } else {
            // If any other key is pressed, reset the count
            resetCount();
          }
        },
      },
    });

    setResizeBtn(formInput, toastEditor);

    // Prevent user from drag'n'dropping images in the editor
    toastEditor.removeHook("addImageBlobHook");

    // Delegate focus from form input to toast ui editor
    formInput.addEventListener("focus", () => {
      toastEditor.focus();
    });
  });
};

const disableImageUpload = () => {
  const target = document.querySelector(".toastui-editor-popup");
  if (!target) {
    return;
  }
  // Reference:https://github.com/nhn/tui.editor/issues/1204#issuecomment-1068364431
  const observer = new MutationObserver(() => {
    target.querySelector('[aria-label="URL"]').click();
    target.querySelector(".toastui-editor-tabs").style.display = "none";
  });

  observer.observe(target, { attributes: true, attributeFilter: ["style"] });
};

const setMarkdownEditorTheme = (theme) => {
  const editors = document.querySelectorAll(".toastui-editor-defaultUI");
  editors.forEach((editor) => {
    const hasDarkTheme = editor.classList.contains("toastui-editor-dark");
    if (
      (hasDarkTheme && theme === "light") ||
      (!hasDarkTheme && theme === "dark")
    ) {
      editor.classList.toggle("toastui-editor-dark");
    }
  });
};

const hasScrollBar = (el) => el.scrollHeight > el.clientHeight;
const toggleScrollbarModifier = (btn, el) => {
  if (el.clientHeight === 0) return;
  btn.classList.toggle(
    "markdown-editor__resize-btn--with-scrollbar",
    hasScrollBar(el)
  );
};
const setResizeBtn = (formInput, editor) => {
  const resizeBtn = document.querySelector(`#${formInput.id}-resize`);
  if (!resizeBtn) return;

  const editorTextArea = editor
    .getEditorElements()
    .mdEditor.querySelector('[contenteditable="true"]');

  toggleScrollbarModifier(resizeBtn, editorTextArea);
  new MutationObserver(() => {
    toggleScrollbarModifier(resizeBtn, editorTextArea);
  }).observe(editorTextArea, {
    attributes: true,
  });

  resizeBtn.addEventListener("click", () => {
    const height = editor.getHeight();

    if (height && height === "300px") {
      editor.setHeight("auto");
      editor.setMinHeight("400px");
      resizeBtn.classList.add("markdown-editor__resize-btn--collapse");
      resizeBtn.title = I18n.t("application.markdown_editor.collapse");
      resizeBtn.ariaLabel = I18n.t("application.markdown_editor.collapse");
    } else {
      editor.setHeight("300px");
      editor.setMinHeight("300px");
      resizeBtn.classList.remove("markdown-editor__resize-btn--collapse");
      resizeBtn.title = I18n.t("application.markdown_editor.expand");
      resizeBtn.ariaLabel = I18n.t("application.markdown_editor.expand");
    }
  });
};

$(document).on("turbolinks:load", function () {
  initializeMarkdownEditors();
  disableImageUpload();
});

$(document).on("theme:change", function (event) {
  const newTheme = event.detail.currentTheme;
  setMarkdownEditorTheme(newTheme);
});
