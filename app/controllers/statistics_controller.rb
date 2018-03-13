class StatisticsController < ApplicationController

  def policy_class
    StatisticsPolicy
  end

  def show
    authorize self
  end

end
