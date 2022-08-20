# frozen_string_literal: true

class PagedownFormBuilder < ActionView::Helpers::FormBuilder
  def pagedown(method, args)
    # Adopt simple form builder to work with form_for
    @attribute_name = method
    @input_html_options = args[:input_html]

    @template.capture do
      @template.concat wmd_button_bar
      @template.concat wmd_textarea
      @template.concat wmd_preview if show_wmd_preview?
    end
  end

  private

  def wmd_button_bar
    @template.tag.div(nil, id: "wmd-button-bar-#{base_id}")
  end

  def wmd_textarea
    @template.text_area @object_name, @attribute_name,
      **@input_html_options,
      class: 'form-control wmd-input',
      id: "wmd-input-#{base_id}"
  end

  def wmd_preview
    @template.tag.div(nil, class: 'wmd-preview',
      id: "wmd-preview-#{base_id}")
  end

  def show_wmd_preview?
    @input_html_options[:preview].present?
  end

  def base_id
    options[:pagedown_id_suffix] || @attribute_name
  end
end
