module TimeHelper

  # convert timestamps ('12:34:56.789') to seconds
  def time_to_f(timestamp)
    unless timestamp.nil?
      timestamp = timestamp.split(':')
      return timestamp[0].to_i * 60 * 60 + timestamp[1].to_i * 60 + timestamp[2].to_f
    end
    nil
  end

end
