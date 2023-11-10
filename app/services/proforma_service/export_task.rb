# frozen_string_literal: true

module ProformaService
  class ExportTask < ServiceBase
    def initialize(exercise: nil)
      super()
      @exercise = exercise
    end

    def execute
      @task = ConvertExerciseToTask.call(exercise: @exercise)
      exporter = ProformaXML::Exporter.new(task: @task)
      exporter.perform
    end
  end
end
