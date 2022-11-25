# frozen_string_literal: true

class MigrateTestruns < ActiveRecord::Migration[6.1]
  # We are not changing any tables but only backfilling data.
  disable_ddl_transaction!

  SPLIT_OUTPUT = Regexp.compile(/(?<meta>message: (?<message>.*)\n|status: (?<status>.*)\n)? stdout: (?<stdout>.*)\n stderr: ?(?<stderr>.*)/m)
  PYTHON_BYTE_OUTPUT = Regexp.compile(/^b'(?<raw_output>.*)'$/)
  PYTHON_JSON_OUTPUT = Regexp.compile(/{"cmd":"write","stream":"(?<stream>.*)","data":"(?<data_output>.*)"}/)
  RUN_OUTPUT = Regexp.compile(%r{(?<prefix>timeout:)? ?(?>make run\r\n)?(?>python3 /usr/lib/[^\r\n]*\r\n|/usr/bin/python3[^\r\n]*\r\n|ruby [^\r\n]*\r\n)?(?<cleaned_output>[^ "\e][^\e]*?[^#\e])?(?<shell>\r\e.*?)?#?(?<suffix>exit|timeout)?\r?\Z}m)
  REAL_EXIT = Regexp.compile(/\A(?>(?<json>(?<json_output>{".*?)?(?>{"cmd":(?> |"write","stream":"stdout","data":)?"#?exit(?>\\[nr])?"})+(?<more_shell_output_after_json>.*))|(?<program_output>.*?)(?>#?exit\s*)+(?<more_shell_output_after_program>.*))\z/m)
  STDERR_WRITTEN = Regexp.compile(/^(?:(?<rb_error>\r*[^\n\r]*\.rb:\d+:.*)|(?<other_error>\r*[^\n\r]*\.java:\d+: error.*|\r*Exception in thread.*|\r*There was .*|\r*[^\n\r]*java\.lang\..*|\r*make: \*\*\* \[.*))\z/m)
  FIND_JSON = Regexp.compile(/{(?:(?:"(?:\\.|[^\\"])+?"\s*:\s*(?:"(?:\\.|[^\\"])*?"|-?\d++(?:\.\d++)?|\[.*?\]|{.*?}|null))+?\s*,?\s*)+}/)
  # We identify incomplete Unicode characters. Valid unicode characters are:
  # \uXXXX, \u{XXXXX}, \udYXX\udZXX with X = 0-9a-f, Y = 89ab, Z = cdef
  # Every incomplete prefix of a valid unicode character is identified
  REPLACE_INCOMPLETE_UNICODE = Regexp.compile(/(?:\\?\\u[\da-f]{0,3}|\\?\\ud[89ab][\da-f]{2}\\?(?:\\(?:u(?:d(?:[cdef][\da-f]?)?)?)?)?|\\?\\u\{[\da-f]{0,4})"}\z/)

  # NOTE: `update_columns` won't run validations nor update the `updated_at` timestamp.
  # This is what we want here, thus we disable Rubocop for this migration.
  # rubocop:disable Rails/SkipsModelValidations
  def up
    ActiveRecord::Base.transaction do
      migrate_cause
      migrate_messages
    end
  end

  private

  def migrate_cause
    Rails.logger.info 'Unifying `cause` for multiple Testruns and Submissions. This might take a while...'

    # Our database contains various causes: "assess, "remoteAssess", "run", "submit"
    # As of 2022, we only differentiate between a "run" and a "assess" execution
    # Other values were never stored programmatically but added
    # with the `20170830083601_add_cause_to_testruns.rb` migration.
    cause_migration = {
      # old_value => new _value
      'remoteAssess' => 'assess',
      'submit' => 'assess',
    }

    Testrun.where(cause: cause_migration.keys).find_each do |testrun|
      # Ensure that the submission has the correct cause
      testrun.submission.update_columns(cause: testrun.cause)

      # Update the testrun with the new cause
      testrun.update_columns(cause: cause_migration[testrun.cause])
    end
  end

  def migrate_messages
    Rails.logger.info 'Migrating Testrun to TestrunMessages using RegEx. This will take a very long time...'

    Testrun.find_each do |testrun|
      result = case testrun.passed
                 when true
                   migrate_successful_score_run(testrun)
                 when false
                   migrate_failed_score_run(testrun)
                 else
                   # The "testrun" is actually a "run" (as stored in `cause`)
                   migrate_code_execution(testrun)
               end

      testrun.update_columns(result.slice(:exit_code, :status))
    end
  end

  def migrate_successful_score_run(testrun)
    # If the testrun passed, we (typically) won't have any output.
    # Thus, we assume that the assessment exited with 0 successfully
    result = {exit_code: 0, status: :ok}
    stdout, stderr = nil

    if testrun.output&.match(PYTHON_BYTE_OUTPUT)
      # Some runs until 2016-04-13 have (useless) output. We could remove them but keep them for now
      #
      # The output is manually converted in a dumped ruby string (from Python) and undumped.
      # All Python test output is printed on STDERR, even for successful code runs.
      dumped_raw_output = Regexp.last_match(:raw_output)&.gsub(/"/, '\\"')
      stderr = "\"#{dumped_raw_output}\"".undump
      # There is no other output format present in the database (checked manually), so nothing for `else`
    end

    store_stdout_stderr(testrun, stdout, stderr)
    result
  end

  def migrate_failed_score_run(testrun)
    # This score run was not successful. We set some defaults and search for more details
    result = {exit_code: 1, status: :failed}
    stdout, stderr = nil

    case testrun.output
      when SPLIT_OUTPUT
        # Output has well-known format. Let's split it and store it in dedicated fields

        # `status` is one of :ok, :failed, :container_depleted, :timeout, :out_of_memory
        # `message` (see RegEx) was prefixed for some time and always contained no value (checked manually)
        result[:status] = Regexp.last_match(:status)&.to_sym || result[:status]
        stdout = Regexp.last_match(:stdout)&.presence
        stderr = Regexp.last_match(:stderr)&.presence
      when PYTHON_BYTE_OUTPUT
        # The output is manually converted in a dumped ruby string (from Python) and undumped
        dumped_raw_output = Regexp.last_match(:raw_output)&.gsub(/"/, '\\"')
        stderr = "\"#{dumped_raw_output}\"".undump
      when PYTHON_JSON_OUTPUT
        # A very few (N=2) assess runs contain a single raw JSON message.
        # To be sure, we grep the stream and data here to store it later again.
        if Regexp.last_match(:stream) == 'stdout'
          stdout = Regexp.last_match(:data_output)
        else
          stderr = Regexp.last_match(:data_output)
        end
      else
        stderr = testrun.output.presence
    end

    # If possible, we try to infer whether this run used make (exit code 2) or not (exit code 1)
    get_exit_code_from_stderr(stderr&.match(STDERR_WRITTEN), result)

    store_stdout_stderr(testrun, stdout, stderr)
    result
  end

  def migrate_code_execution(testrun)
    # The `output` variable is modified several times throughout this script.
    # Thus, we make a copy and modify it to remove control information, shell command lines,
    # and any other unwanted strings that are not part of the program execution.
    output = testrun.output

    # A reference to the `result` variable is passed to each processing method and modified there
    # Order of `status` interpretation: `Failure` before `Exit` before `timeout` before `ok`
    result = {status: :ok, exit_code: 0}

    output = code_execution_trim(output, result)
    output = code_execution_search_for_exit(output, result)
    # Now, we either know that
    # - the program terminated (status = :ok) or
    # - the execution timed-out (status = :timeout) or
    # - that the information is not present in the data (e.g., because it was truncated). In this case, we need
    #   to assume successful termination. Further "guessing" is performed below based on the output.

    code_execution_process_json(testrun, output, result)

    # If we found JSON input, we're done and can continue with saving our changes.
    # Otherwise, we need to continue here...
    code_execution_process_raw(testrun, output, result) unless result[:json_output]

    result
  end

  def code_execution_trim(output, result)
    # First, we apply some pre-processing:
    # - Identify `timeout: ` and `timeout:` prefixes
    # - Identify `#exit`, `#timeout` suffixes (with optional # and \n)
    # - Clean remaining output and remove trailing "make run", "python3 /usr/lib/...", "/usr/bin/python3 ...", and "ruby ..." lines.
    # - Additionally, (multiple) trailing " (from Python) are removed so that these start with {" (a usual JSON)
    # - Also, remove any shell output by identifying \e (ESC) - filter checked manually
    pre_processing = output&.match(RUN_OUTPUT)

    if pre_processing.present?
      # The `prefix` might only be `timeout:`. We use that.
      result[:status] = :timeout if pre_processing[:prefix] == 'timeout:'

      # The `suffix` might be `timeout` or `exit`.
      # As sometimes the execution was not identified as `exited`, a `timeout` was reached.
      # Here, we want to "restore" the original status: If the execution `exited`, we ignore the `timeout`.
      result[:status] = :timeout if pre_processing[:suffix] == 'timeout'
      result[:status] = :ok if pre_processing[:suffix] == 'exit'

      # For further processing, we continue using our cleaned_output
      output = pre_processing[:cleaned_output]

      # Other shell output is ignored by design.
      # pre_processing[:shell]
    end

    output
  end

  def code_execution_search_for_exit(output, result)
    # Second, we check for (another) presence of an `exit`.
    # This time, we consider the following variances:
    # - {"cmd": "exit"}
    # - {"cmd":"exit"}
    # - #exit
    # - exit
    # The text until the first `exit` is recognized will be treated as the original output
    # Any text that is included after the last `exit` is considered as further shell output (and thus ignored).
    search_for_exit = output&.match(REAL_EXIT)

    # If we find an `exit` identifier, we also know whether JSON was processed or not.
    # That information is stored for further processing. If not found, we don't assume JSON.
    result[:json_output] = false

    if search_for_exit.present? # Nothing matched, we don't have any exit code
      output = search_for_exit[:json_output] || search_for_exit[:program_output]
      result[:status] = :ok

      # Check whether the first group with JSON data matched.
      result[:json_output] = search_for_exit[:json]

      # Other shell output is ignored by design.
      # search_for_exit[:more_shell_output_after_json] || search_for_exit[:more_shell_output_after_program]
    end

    output
  end

  def code_execution_process_json(testrun, output, result)
    # Third, we parse JSON messages and split those into their streams
    # Before doing so, we try to close the last JSON message (which was probably cut off hard)
    # Either, we need to end the current string with " and close the object with } or just close the object.
    if output.present? && output.count('{') != output.count('}')
      # Remove single trailing escape character
      output.delete_suffix!('\\') if (output.ends_with?('\\') && !output.ends_with?('\\\\')) || (output.ends_with?('\\\\\\') && !output.ends_with?('\\\\\\\\'))
      if (output.ends_with?('"') || output.ends_with?('{')) && !output.ends_with?('\"')
        output += '}'
      else
        output += '"}'
      end
      # Remove incomplete unicode characters (usually \u0061) at the end of the JSON
      output = output.gsub(REPLACE_INCOMPLETE_UNICODE, '"}')
    end
    # Then, we look for valid JSON parts and parse them.
    unparsed_json_messages = output&.scan(FIND_JSON) || []
    parsed_json_messages = unparsed_json_messages.map {|message| JSON.parse(message) }

    parsed_json_messages.each_with_index do |json, index|
      create_testrun_message(testrun, json, index + 1) # Index is starting with 0.

      # It is very likely that any presence of stderr indicates an unsuccessful execution.
      next unless json['stream'] == 'stderr'

      result[:status] = :failed
      result[:exit_code] = 1
      # If possible, we try to infer whether this run used make (exit code 2) or not (exit code 1)
      get_exit_code_from_stderr(json['data']&.match(STDERR_WRITTEN), result)
    end

    result[:json_output] = parsed_json_messages.present?
  end

  def code_execution_process_raw(testrun, output, result)
    # Forth, we want to separate the remaining `output` into STDOUT and STDERR.
    # In this step, we also infer whether the program exited normally or unexpectedly.
    errors = output&.match(STDERR_WRITTEN) || {}
    # Probably, only one of `rb_error` or `other_error` is filled. We want to be sure and concatenate both
    stderr = "#{errors[:rb_error]}#{errors[:rb_error]}"
    stdout = output&.delete_suffix(stderr) || output # Fallback to full output in case nothing matched

    get_exit_code_from_stderr(errors, result)

    store_stdout_stderr(testrun, stdout, stderr)
    result
  end

  def get_exit_code_from_stderr(stderr_match, result)
    # As the exit code is not recorded yet, we define some rules
    # - An output containing ".java:<line No>: error" had a syntax error (Java)
    # - An output containing "Exception in thread " or "java.lang." had a runtime exception (Java)
    # - An output containing ".rb:<line No>:" also had some error (Ruby)
    # - An output containing "make: *** [<target>] Error <int>" failed (somewhere)
    # - (No dedicated search for R, JS, required [e.g., because of using make])
    # In our use case, `make` either returns `0` for success or `2` for any error (regardless of the <int> shown).
    # For others, we set the exit code to `1` (as done by Ruby or other interpreters)

    return if stderr_match.nil?

    if stderr_match[:rb_error].present?
      # Ruby is used without make and normally exists with `1` in case of an error
      result[:exit_code] = 1
      result[:status] = :failed
    elsif stderr_match[:other_error].present?
      # `make` was used and the exit code was `2` (according to `man` page)
      result[:exit_code] = 2
      result[:status] = :failed
    end
  end

  def store_stdout_stderr(testrun, stdout, stderr)
    # Create two messages based on our split messages.
    # We assume that (most likely) STDOUT was written before STDERR
    order = 0 # Incremented before storing any value
    create_testrun_message(testrun, {'cmd' => 'write', 'stream' => 'stdout', 'data' => stdout}, order += 1) if stdout.present?
    create_testrun_message(testrun, {'cmd' => 'write', 'stream' => 'stderr', 'data' => stderr}, order + 1) if stderr.present?
  end

  def create_testrun_message(testrun, json, order)
    # Using the string keys by design. Otherwise, we would need to call #symbolize_keys!

    message = {
      testrun:,
      cmd: json['cmd'],
      # We cannot infer any timestamp and thus use arbitrary, distinct millisecond values (1s = 1000ms)
      timestamp: ActiveSupport::Duration.build(order / 1000.0),
      created_at: testrun.created_at,
      updated_at: testrun.updated_at,
    }

    if json.key?('stream') && json.key?('data')
      message[:stream] = json['stream']
      message[:log] = json['data']
    else
      message[:data] = json.except('cmd').presence
    end

    begin
      TestrunMessage.create(message)
    rescue StandardError
      # We ignore any error here. This probably indicates that the JSON recovered from the output was invalid
      # An invalid JSON might be caused by our arbitrary truncation...
    end
  end

  # rubocop:enable Rails/SkipsModelValidations
end
