# frozen_string_literal: true

module Webpacker::SriHelperExtensions
  def stylesheet_link_tag(*sources, **options)
    tags = sources.map do |stylesheet|
      if stylesheet.is_a?(Hash)
        super(stylesheet[:src], options.merge(integrity: stylesheet[:integrity]))
      else
        super(stylesheet, options)
      end
    end
    safe_join(tags)
  end

  def javascript_include_tag(*sources, **options)
    tags = sources.map do |javascript|
      if javascript.is_a?(Hash)
        super(javascript[:src], options.merge(integrity: javascript[:integrity]))
      else
        super(javascript, options)
      end
    end
    safe_join(tags)
  end
end

if Sprockets::Rails::Helper.ancestors.map(&:name).exclude?(Webpacker::SriHelperExtensions.name)
  Sprockets::Rails::Helper.prepend(Webpacker::SriHelperExtensions)
end
