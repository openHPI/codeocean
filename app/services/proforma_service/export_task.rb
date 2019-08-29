# frozen_string_literal: true

module ProformaService
  class ExportTask < ServiceBase
    def initialize(exercise: nil)
      @exercise = exercise
    end

    def execute
      @task = ConvertExerciseToTask.call(exercise: @exercise)
      exporter = Proforma::Exporter.new(@task)
      exporter.perform
    end
  end
end
