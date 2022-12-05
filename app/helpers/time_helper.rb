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
    format_time(delta, '%H:%M:%S')
  end

  # given a delta in seconds, return a "Hours:Minutes:Seconds.Milliseconds" representation
  def format_time_difference_detailed(delta)
    format_time(delta, '%H:%M:%S.%L')
  end

  # given a ISO8601 duration (PT27M47.975972S), return a ActiveSupport::Duration
  def parse_duration(duration)
    return ActiveSupport::Duration.build(0) if duration.nil?

    ActiveSupport::Duration.parse(duration)
  end

  private

  def format_time(delta, format)
    unless delta.is_a?(Numeric)
      delta = parse_duration(delta)
    end

    Time.at(delta).utc.strftime(format)
  end
end
