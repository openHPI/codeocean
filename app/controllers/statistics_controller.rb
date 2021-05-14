# frozen_string_literal: true

class StatisticsController < ApplicationController
  include StatisticsHelper

  before_action :authorize!, only: %i[show graphs user_activity user_activity_history rfc_activity
                                      rfc_activity_history]

  def policy_class
    StatisticsPolicy
  end

  def show
    respond_to do |format|
      format.html
      format.json { render(json: statistics_data) }
    end
  end

  def graphs; end

  def user_activity
    respond_to do |format|
      format.json { render(json: user_activity_live_data) }
    end
  end

  def user_activity_history
    respond_to do |format|
      format.html { render('activity_history', locals: {resource: :user}) }
      format.json { render_ranged_data :ranged_user_data }
    end
  end

  def rfc_activity
    respond_to do |format|
      format.json { render(json: rfc_activity_data) }
    end
  end

  def rfc_activity_history
    respond_to do |format|
      format.html { render('activity_history', locals: {resource: :rfc}) }
      format.json { render_ranged_data :ranged_rfc_data }
    end
  end

  def render_ranged_data(data_source)
    interval = params[:interval].to_s.empty? ? 'year' : params[:interval]
    from = begin
      DateTime.strptime(params[:from], '%Y-%m-%d')
    rescue StandardError
      DateTime.new(0)
    end
    to = begin
      DateTime.strptime(params[:to], '%Y-%m-%d')
    rescue StandardError
      DateTime.now
    end
    render(json: send(data_source, interval, from, to))
  end

  def authorize!
    authorize self
  end
  private :authorize!
end
