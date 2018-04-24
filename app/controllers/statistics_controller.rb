class StatisticsController < ApplicationController
  include StatisticsHelper

  before_action :authorize!, only: [:show, :graphs, :user_activity, :user_activity_history, :rfc_activity,
                                    :rfc_activity_history]

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

  def user_activity_history
  end

  def rfc_activity
    respond_to do |format|
      format.json { render(json: rfc_activity_data) }
    end
  end

  def rfc_activity_history
    respond_to do |format|
      format.html { render 'rfc_activity_history' }
      format.json do
        interval = params[:interval] || 'year'
        from = DateTime.strptime(params[:from], '%Y-%M-%D') rescue DateTime.new(0)
        to = DateTime.strptime(params[:to], '%Y-%M-%D') rescue DateTime.now
        render(json: ranged_rfc_data(interval, from, to))
      end
    end
  end

  def authorize!
    authorize self
  end
  private :authorize!

end
