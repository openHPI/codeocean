/**
 * ToastUi editor initializer
 *
 * This script transforms form textareas created with
 * "MarkdownFormBuilder" into ToastUi markdown editors.
 *
 */

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
      resizeBtn.title = I18n.t("markdown_editor.collapse");
      resizeBtn.ariaLabel = I18n.t("markdown_editor.collapse");
    } else {
      editor.setHeight("300px");
      editor.setMinHeight("300px");
      resizeBtn.classList.remove("markdown-editor__resize-btn--collapse");
      resizeBtn.title = I18n.t("markdown_editor.expand");
      resizeBtn.ariaLabel = I18n.t("markdown_editor.expand");
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
