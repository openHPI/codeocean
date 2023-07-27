# frozen_string_literal: true

class ServiceBase
  def self.call(**)
    new(**).execute
  end
end
