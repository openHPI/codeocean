# frozen_string_literal: true

module ProformaService
  class ExportTask < ServiceBase
    def initialize(exercise: nil)
      super()
      @exercise = exercise
    end

    def execute
      @task = ConvertExerciseToTask.call(exercise: @exercise)
      namespaces = [{prefix: 'CodeOcean', uri: 'codeocean.openhpi.de'}]
      exporter = Proforma::Exporter.new(task: @task, custom_namespaces: namespaces)
      exporter.perform
    end
  end
end
