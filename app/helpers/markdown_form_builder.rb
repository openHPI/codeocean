# frozen_string_literal: true

class MarkdownFormBuilder < ActionView::Helpers::FormBuilder
  def markdown(method, args = {})
    # Adopt simple form builder to work with form_for
    @attribute_name = method
    @input_html_options = args[:input_html]

    @template.capture do
      @template.concat form_textarea
      @template.concat @template.tag.div(class: 'markdown-editor', data: {behavior: 'markdown-editor-widget', id: label_target})
    end
  end

  private

  def form_textarea
    @template.text_area @object_name, @attribute_name,
    **(@input_html_options || {}),
      id: label_target,
      class: 'd-none'
  end

  def base_id
    options[:markdown_id_suffix] || @attribute_name
  end

  def label_target
    "markdown-input-#{base_id}"
  end
end
