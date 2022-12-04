# frozen_string_literal: true

module ApplicationHelper
  APPLICATION_NAME = 'CodeOcean'

  def application_name
    APPLICATION_NAME
  end

  def code_tag(code, language = nil)
    if code.present?
      tag.pre do
        tag.code(code, class: "language-#{language}")
      end
    else
      empty
    end
  end

  def empty
    tag.i(nil, class: 'empty fa-solid fa-minus')
  end

  def label_column(label)
    tag.div(class: 'col-md-3') do
      tag.strong do
        I18n.exists?("activerecord.attributes.#{label}") ? t("activerecord.attributes.#{label}") : t(label)
      end
    end
  end
  private :label_column

  def no
    tag.i(nil, class: 'fa-solid fa-xmark')
  end

  def per_page_param
    if params[:per_page]
      [params[:per_page].to_i, 100].min
    else
      WillPaginate.per_page
    end
  end

  def progress_bar(value)
    tag.div(class: value ? 'progress' : 'disabled progress') do
      tag.div(value ? "#{value}%" : '', 'aria-valuemax': 100, 'aria-valuemin': 0,
        'aria-valuenow': value, class: 'progress-bar progress-bar-striped', role: 'progressbar', style: "width: #{[value || 0, 100].min}%;")
    end
  end

  def render_markdown(markdown)
    ActionController::Base.helpers.sanitize Kramdown::Document.new(markdown).to_html
  end

  def row(options = {}, &)
    tag.div(class: 'attribute-row row') do
      label_column(options[:label]) + value_column(options[:value], &)
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
    tag.div(class: 'col-md-9') do
      block_given? ? yield : symbol_for(value)
    end
  end
  private :value_column

  def yes
    tag.i(nil, class: 'fa-solid fa-check')
  end
end
