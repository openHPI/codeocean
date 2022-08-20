# frozen_string_literal: true

class ServiceBase
  def self.call(**args)
    new(**args).execute
  end
end
