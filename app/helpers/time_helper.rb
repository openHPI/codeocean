# frozen_string_literal: true

module TimeHelper
  # convert timestamps ('12:34:56.789') to seconds
  def time_to_f(timestamp)
    unless timestamp.nil?
      timestamp = timestamp.split(':')
      return (timestamp[0].to_i * 60 * 60) + (timestamp[1].to_i * 60) + timestamp[2].to_f
    end
    nil
  end

  # given a delta in seconds, return a "Hours:Minutes:Seconds" representation
  def format_time_difference(delta)
    Time.at(delta).utc.strftime('%H:%M:%S')
  end
end
