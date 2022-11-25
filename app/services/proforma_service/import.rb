# frozen_string_literal: true

module ProformaService
  class Import < ServiceBase
    def initialize(zip:, user:)
      super()
      @zip = zip
      @user = user
    end

    def execute
      if single_task?
        importer = Proforma::Importer.new(zip: @zip)
        import_result = importer.perform
        @task = import_result[:task]

        exercise = base_exercise
        exercise_files = exercise&.files&.to_a

        exercise = ConvertTaskToExercise.call(task: @task, user: @user, exercise:)
        exercise_files&.each(&:destroy) # feels suboptimal

        exercise
      else
        import_multi
      end
    end

    private

    def base_exercise
      exercise = Exercise.find_by(uuid: @task.uuid)
      if exercise
        raise Proforma::ExerciseNotOwned unless ExercisePolicy.new(@user, exercise).update?

        exercise
      else
        Exercise.new(uuid: @task.uuid, unpublished: true)
      end
    end

    def import_multi
      Zip::File.open(@zip.path) do |zip_file|
        zip_files = zip_file.filter {|entry| entry.name.match?(/\.zip$/) }
        begin
          zip_files.map! do |entry|
            store_zip_entry_in_tempfile entry
          end
          zip_files.map do |proforma_file|
            Import.call(zip: proforma_file, user: @user)
          end
        ensure
          zip_files.each(&:unlink)
        end
      end
    end

    def store_zip_entry_in_tempfile(entry)
      tempfile = Tempfile.new(entry.name)
      tempfile.write entry.get_input_stream.read.force_encoding('UTF-8')
      tempfile.rewind
      tempfile
    end

    def single_task?
      filenames = Zip::File.open(@zip.path) do |zip_file|
        zip_file.map(&:name)
      end

      filenames.select {|f| f[/\.xml$/] }.any?
    rescue Zip::Error
      raise Proforma::InvalidZip
    end
  end
end
