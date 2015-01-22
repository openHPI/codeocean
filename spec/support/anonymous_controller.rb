class AnonymousController < ApplicationController
  def flash
    @flash ||= {}
  end

  def redirect_to(*options)
  end

  def session
    @session ||= {}
  end
end
