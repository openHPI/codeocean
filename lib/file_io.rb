# frozen_string_literal: true

# stolen from: https://makandracards.com/makandra/50526-fileio-writing-strings-as-carrierwave-uploads
class FileIO < StringIO
  def initialize(stream, filename)
    super(stream)
    @original_filename = filename
  end

  attr_reader :original_filename
end
