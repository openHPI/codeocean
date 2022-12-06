# frozen_string_literal: true

class PingController < ApplicationController
  before_action :postgres_connected!
  after_action :verify_authorized, except: %i[index]

  def index
    render json: {
      message: 'Pong',
      timenow_in_time_zone____: DateTime.now.in_time_zone.to_i,
      timenow_without_timezone: DateTime.now.to_i,
    }
  end

  private

  def postgres_connected!
    # any unhandled exception leads to a HTTP 500 response.
    return if ApplicationRecord.connection.exec_query('SELECT 1 as result').first['result'] == 1

    raise ActiveRecord::ConnectionNotEstablished
  end
end
