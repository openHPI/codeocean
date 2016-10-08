module ApplicationHelper
  APPLICATION_NAME = 'CodeOcean'

  def application_name
    APPLICATION_NAME
  end

  def code_tag(code)
    if code.present?
      content_tag(:pre) do
        content_tag(:code, code)
      end
    else
      empty
    end
  end

  def empty
    content_tag(:i, nil, class: 'empty fa fa-minus')
  end

  def label_column(label)
    content_tag(:div, class: 'col-sm-3') do
      content_tag(:strong) do
        I18n.translation_present?("activerecord.attributes.#{label}") ? t("activerecord.attributes.#{label}") : t(label)
      end
    end
  end
  private :label_column

  def no
    content_tag(:i, nil, class: 'fa fa-times')
  end

  def progress_bar(value)
    content_tag(:div, class: value ? 'progress' : 'disabled progress') do
      content_tag(:div, value ? "#{value}%" : '', :'aria-valuemax' => 100, :'aria-valuemin' => 0, :'aria-valuenow' => value, class: 'progress-bar progress-bar-striped', role: 'progressbar', style: "width: #{[value || 0, 100].min}%;")
    end
  end

  def render_markdown(markdown)
    Kramdown::Document.new(markdown).to_html.html_safe
  end

  def row(options = {}, &block)
    content_tag(:div, class: 'attribute-row row') do
      label_column(options[:label]) + value_column(options[:value], &block)
    end
  end

  def symbol_for(value)
    if value.is_a?(FalseClass)
      no
    elsif value.is_a?(TrueClass)
      yes
    elsif value.blank?
      empty
    else
      value.to_s
    end
  end

  def value_column(value)
    content_tag(:div, class: 'col-sm-9') do
      block_given? ? yield : symbol_for(value)
    end
  end
  private :value_column

  def yes
    content_tag(:i, nil, class: 'fa fa-check')
  end
end
