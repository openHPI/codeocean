# frozen_string_literal: true

class Runner::Connection::Buffer
  # The WebSocket connection might group multiple lines. For further processing, we require all lines
  # to be processed separately. Therefore, we split the lines by each newline character not part of an enclosed
  # substring either in single or double quotes (e.g., within a JSON). Originally, each line break consists of `\r\n`.
  # We keep the `\r` at the end of the line (keeping "empty" lines) and replace it after buffering.
  # Inspired by https://stackoverflow.com/questions/13040585/split-string-by-spaces-properly-accounting-for-quotes-and-backslashes-ruby
  SPLIT_INDIVIDUAL_LINES = Regexp.compile(/(?:"(?:\\"|[^"])*"|'(?:\\'|[^'])*'|[^\n])+/)

  def initialize
    @global_buffer = +''
    @buffering = false
    @line_buffer = Queue.new
    super
  end

  def store(event_data)
    # First, we append the new data to the existing `@global_buffer`.
    # Either, the `@global_buffer` is empty and this is a NO OP.
    # Or, the `@global_buffer` contains an incomplete string and thus requires the new part.
    @global_buffer += event_data
    # We process the full `@global_buffer`. Valid parts are removed from the buffer and
    # the remaining invalid parts are still stored in `@global_buffer`.
    @global_buffer = process_and_split @global_buffer
  end

  def events
    # Return all items from `@line_buffer` in an array (which is iterable) and clear the queue
    Array.new(@line_buffer.size) { @line_buffer.pop }
  end

  def flush
    raise Error::NotEmpty unless @line_buffer.empty?

    remaining_buffer = @global_buffer
    @buffering = false
    @global_buffer = +''
    remaining_buffer
  end

  def empty?
    @line_buffer.empty? && @global_buffer.empty?
  end

  private

  def process_and_split(message_parts, stop: false)
    # We need a temporary buffer to operate on
    buffer = +''
    # We split lines by `\n` and want to normalize them to be separated by `\r\n`.
    # This allows us to identify a former line end with `\r` (as the `\n` is not matched)
    # All results returned from this buffer are normalized to feature `\n` line endings.
    message_parts.encode(crlf_newline: true).scan(SPLIT_INDIVIDUAL_LINES).each do |line|
      # Same argumentation as above: We can always append (previous empty or invalid)
      buffer += line

      if buffering_required_for? buffer
        @buffering = true
        # Check the existing substring `buffer` if it contains a valid message.
        # The remaining buffer is stored for further processing.
        buffer = process_and_split buffer, stop: true unless stop
      else
        add_to_line_buffer(buffer)
        # Clear the current buffer.
        buffer = +''
      end
    end
    # Return the remaining buffer which might become the `@global_buffer`
    buffer
  end

  def add_to_line_buffer(message)
    @buffering = false
    @global_buffer = +''
    # For our buffering, we identified line breaks with the `\n` and removed those temporarily.
    # Thus, we now re-add the `\n` at the end of the string and remove the `\r` at the same time.
    message = message.gsub(/\r$/, "\n")
    @line_buffer.push message
  end

  def buffering_required_for?(message)
    # First, check if the message is very short and start with {
    return true if message.size <= 5 && message.start_with?(/\s*{/)

    invalid_json = !valid_json?(message)
    # Second, if we have the beginning of a valid command but an invalid JSON
    return true if invalid_json && message.start_with?(/\s*{"cmd/)
    # Third, buffer the message if it contains long messages (e.g., an image or turtle batch commands)
    return true if invalid_json && (message.start_with?('<img') || message.include?('"turtlebatch"'))

    # If nothing applies, we don't want to buffer the current message
    false
  end

  def currently_buffering?
    @buffering
  end

  def valid_json?(data)
    # Try parsing the JSON. If that is successful, we have a valid JSON (otherwise not)
    JSON.parse(data)
    # Additionally, check if the string ends with \r and return that result.
    # All JSON messages received through the Runner::Connection will end in a line break!
    data.end_with?("\r")
  rescue JSON::ParserError
    false
  end
end
