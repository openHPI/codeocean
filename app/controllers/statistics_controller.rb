class StatisticsController < ApplicationController
  include StatisticsHelper

  def policy_class
    StatisticsPolicy
  end

  def show
    authorize self
    respond_to do |format|
      format.html
      format.json { render(json: statistics_data) }
    end
  end

  def graphs
    authorize self
    respond_to do |format|
      format.html
      format.json { render(json: graph_live_data) }
    end
  end

end
