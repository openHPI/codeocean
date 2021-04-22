# frozen_string_literal: true

module FileParameters
  def reject_illegal_file_attributes(exercise_id, params)
    if Exercise.exists?(id: exercise_id) && params
      params.reject do |_, file_attributes|
        file = CodeOcean::File.find_by(id: file_attributes[:file_id])
        file.nil? || file.hidden || file.read_only
      end
    else
      []
    end
  end
  private :reject_illegal_file_attributes

  def file_attributes
    %w[content context_id feedback_message file_id file_type_id hidden id name native_file path read_only role weight file_template_id]
  end
  private :file_attributes
end
