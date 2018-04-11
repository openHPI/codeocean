class StatisticsController < ApplicationController
  include StatisticsHelper

  before_action :authorize!, only: [:show, :graphs, :user_activity, :rfc_activity]

  def policy_class
    StatisticsPolicy
  end

  def show
    respond_to do |format|
      format.html
      format.json { render(json: statistics_data) }
    end
  end

  def graphs
  end

  def user_activity
    respond_to do |format|
      format.json { render(json: user_activity_live_data) }
    end
  end

  def rfc_activity
    respond_to do |format|
      format.json { render(json: rfc_activity_live_data) }
    end
  end

  def authorize!
    authorize self
  end
  private :authorize!

end
