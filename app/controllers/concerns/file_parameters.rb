# frozen_string_literal: true

module FileParameters
  def reject_illegal_file_attributes(exercise, params)
    if exercise && params
      params.reject do |_, file_attributes|
        file = CodeOcean::File.find_by(id: file_attributes[:file_id])
        # avoid that public files from other contexts can be created
        file.nil? || file.hidden || file.read_only || file.context_type == 'Exercise' && file.context_id != exercise.id
      end
    else
      []
    end
  end
  private :reject_illegal_file_attributes

  def file_attributes
    %w[content context_id feedback_message file_id file_type_id hidden id name native_file path read_only role weight
       file_template_id]
  end
  private :file_attributes
end
