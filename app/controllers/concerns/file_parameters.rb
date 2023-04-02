# frozen_string_literal: true

module FileParameters
  def reject_illegal_file_attributes(exercise, params)
    if exercise && params
      # We only want to load the files once, to avoid multiple database queries.
      # Further, we use `unscope` to avoid that the `order` scope is applied
      # Optimization: We query for the `file_type` here, which is used in `CodeOcean::File#set_ancestor_values`.
      files = CodeOcean::File.unscope(:order).where(id: params.values.pluck(:file_id)).includes(:file_type)

      params.reject do |_, file_attributes|
        # This mechanism seems cumbersome, but we cannot use an index here.
        # The ordering of the files is not guaranteed to be the same as the ordering of the file attributes.
        file = files.find {|f| f.id == file_attributes[:file_id].to_i }

        next true if file.nil? || file.hidden || file.read_only
        # avoid that public files from other contexts can be created
        # `next` is similar to an early return and will proceed with the next iteration of the loop
        next true if file.context_type == 'Exercise' && file.context_id != exercise.id
        next true if file.context_type == 'Submission' && (file.context.user_id != current_user.id || file.context.user_type != current_user.class.name)
        next true if file.context_type == 'CommunitySolution' && controller_name != 'community_solutions'

        # Optimization: We already queried the ancestor file, let's reuse the object.
        file_attributes[:file] = file
        file_attributes.delete(:file_id)

        false
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
