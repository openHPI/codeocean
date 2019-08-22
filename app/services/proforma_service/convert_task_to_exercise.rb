# frozen_string_literal: true

module ProformaService
  class ConvertTaskToExercise < ServiceBase
    def initialize(task:, user:, exercise: nil)
      @task = task
      @user = user
      @exercise = exercise || Exercise.new
    end

    def execute
      import_exercise
      @exercise
    end

    private

    def import_exercise
      @exercise.assign_attributes(
        user: @user,
        title: @task.title,
        description: @task.description,
        instructions: @task.internal_description,
        files: files
        # tests: tests,
        # execution_environment: execution_environment,
        # state_list: @exercise.persisted? ? 'updated' : 'new'
      )
    end

    def files
      test_files + task_files.values
    end

    def test_files
      @task.tests.map do |test_object|
        task_files.delete(test_object.files.first.id).tap do |file|
          file.weight = 1.0
          file.feedback_message = test_object.meta_data['feedback-message']
        end
      end
    end

    def task_files
      @task_files ||= Hash[
        @task.all_files.reject { |file| file.id == 'ms-placeholder-file' }.map do |task_file|
          [task_file.id, codeocean_file_from_task_file(task_file)]
        end
      ]
    end

    def codeocean_file_from_task_file(file)

      CodeOcean::File.new(
        context: @exercise,
        content: file.content,
        file_type: FileType.find_by(file_extension: File.extname(file.filename)),
        hidden: file.visible == 'no',
        name: File.basename(file.filename, '.*'),
        read_only: file.usage_by_lms != 'edit',
        # native_file: somehting something, uploader something
        role: file.internal_description.underscore.gsub(' ', '_'),
        # feedback_message: file.purpose == 'test' ? file.test.feedback_message : nil,
        # weight: file.test? ? 1.0 : nil,
        path: File.dirname(file.filename)
      )

      # ExerciseFile.new({
      #   full_file_name: task_file.filename,
      #   read_only: task_file.usage_by_lms.in?(%w[display download]),
      #   hidden: task_file.visible == 'no',
      #   role: task_file.internal_description
      # }.tap do |params|
      #   if task_file.binary
      #     params[:attachment] = file_base64(task_file)
      #     params[:attachment_file_name] = task_file.filename
      #     params[:attachment_content_type] = task_file.mimetype
      #   else
      #     params[:content] = task_file.content
      #   end
      # end)
    end

    def file_base64(file)
      "data:#{file.mimetype || 'image/jpeg'};base64,#{Base64.encode64(file.content)}"
    end
  end
end
