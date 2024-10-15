# frozen_string_literal: true

require 'mimemagic'

module ProformaService
  class ConvertExerciseToTask < ServiceBase
    DEFAULT_LANGUAGE = 'de'

    def initialize(exercise: nil)
      super()
      @exercise = exercise
    end

    def execute
      create_task
    end

    private

    def create_task
      ProformaXML::Task.new(
        {
          title: @exercise.title,
          description: @exercise.description,
          internal_description: nil,
          proglang:,
          files: task_files,
          tests:,
          uuid:,
          language: DEFAULT_LANGUAGE,
          model_solutions:,
          meta_data: {
            '@@order' => %w[meta-data],
            'meta-data' => {
              '@@order' => %w[CodeOcean:public CodeOcean:hide_file_tree CodeOcean:allow_file_creation CodeOcean:allow_auto_completion CodeOcean:expected_difficulty CodeOcean:execution_environment_id CodeOcean:files],
              '@xmlns' => {'CodeOcean' => 'codeocean.openhpi.de'},
              'CodeOcean:public' => {
                '@@order' => %w[$1],
                '$1' => @exercise.public,
              },
              'CodeOcean:hide_file_tree' => {
                '@@order' => %w[$1],
                '$1' => @exercise.hide_file_tree,
              },
              'CodeOcean:allow_file_creation' => {
                '@@order' => %w[$1],
                '$1' => @exercise.allow_file_creation,
              },
              'CodeOcean:allow_auto_completion' => {
                '@@order' => %w[$1],
                '$1' => @exercise.allow_auto_completion,
              },
              'CodeOcean:expected_difficulty' => {
                '@@order' => %w[$1],
                '$1' => @exercise.expected_difficulty,
              },
              'CodeOcean:execution_environment_id' => {
                '@@order' => %w[$1],
                '$1' => @exercise.execution_environment_id,
              },
              'CodeOcean:files' => task_files_meta_data,
            },
          },
        }.compact
      )
    end

    def proglang
      regex = %r{^openhpi/co_execenv_(?<language>[^:]*):(?<version>[^-]*)(?>-.*)?$}
      match = regex.match @exercise&.execution_environment&.docker_image
      match ? {name: match[:language], version: match[:version]} : nil
    end

    def uuid
      @exercise.update(uuid: SecureRandom.uuid) if @exercise.uuid.nil?
      @exercise.uuid
    end

    def model_solutions
      @exercise.files.filter(&:reference_implementation?).group_by {|file| xml_id_from_file(file).first }.map do |xml_id, files|
        ProformaXML::ModelSolution.new(
          id: xml_id,
          files: files.map {|file| model_solution_file(file) }
        )
      end
    end

    def model_solution_file(file)
      task_file(file).tap do |ms_file|
        ms_file.used_by_grader = false
        ms_file.usage_by_lms = 'display'
      end
    end

    def tests
      @exercise.files.filter(&:teacher_defined_assessment?).group_by {|file| xml_id_from_file(file).first }.map do |xml_id, files|
        ProformaXML::Test.new(
          id: xml_id,
          title: files.first.name,
          files: files.map {|file| test_file(file) },
          meta_data: test_meta_data(files)
        )
      end
    end

    def xml_id_from_file(file)
      xml_id_path = file.xml_id_path || []
      return xml_id_path if xml_id_path&.any?

      type = if file.teacher_defined_assessment?
               'test'
             elsif file.reference_implementation?
               'ms'
             else
               'file'
             end

      xml_id_path << "co-#{type}-#{file.id}" unless type == 'file'
      xml_id_path << file.id.to_s

      xml_id_path
    end

    def test_meta_data(files)
      {
        '@@order' => %w[test-meta-data],
        'test-meta-data' => {
          '@@order' => %w[CodeOcean:test-file],
          '@xmlns' => {'CodeOcean' => 'codeocean.openhpi.de'},
          'CodeOcean:test-file' => files.map do |file|
            {
              '@@order' => %w[CodeOcean:feedback-message CodeOcean:weight CodeOcean:hidden-feedback],
              '@xmlns' => {'CodeOcean' => 'codeocean.openhpi.de'},
              '@id' =>  xml_id_from_file(file).last,
              '@name' => file.name,
              'CodeOcean:feedback-message' => {
                '@@order' => %w[$1],
                '$1' => file.feedback_message,
              },
              'CodeOcean:weight' => {
                '@@order' => %w[$1],
                '$1' => file.weight,
              },
              'CodeOcean:hidden-feedback' => {
                '@@order' => %w[$1],
                '$1' => file.hidden_feedback,
              },
            }
          end,
        },
      }
    end

    def test_file(file)
      task_file(file).tap do |t_file|
        t_file.used_by_grader = true
      end
    end

    def exercise_files
      @exercise.files.filter do |file|
        !file.role.in? %w[reference_implementation teacher_defined_test
                          teacher_defined_linter]
      end
    end

    def task_files_meta_data
      task_files_hash = {
        '@@order' => [],
      }

      exercise_files.each do |file|
        task_files_hash['@@order'] << "CodeOcean:CO-#{file.id}"
        task_files_hash["CodeOcean:CO-#{file.id}"] = {
          '@@order' => ['CodeOcean:role'],
          'CodeOcean:role' => {
            '@@order' => ['$1'],
            '$1' => file.role,
          },
        }
      end

      task_files_hash
    end

    def task_files
      exercise_files.map do |file|
        task_file(file)
      end
    end

    def task_file(file)
      file.update(xml_id_path: xml_id_from_file(file)) if file.xml_id_path.blank?

      xml_id = xml_id_from_file(file).last
      task_file = ProformaXML::TaskFile.new(
        id: xml_id,
        filename: filename(file),
        usage_by_lms: file.read_only ? 'display' : 'edit',
        visible: file.hidden ? 'no' : 'yes'
      )
      add_content_to_task_file(file, task_file)
      task_file
    end

    def filename(file)
      if file.path.present? && file.path != '.'
        ::File.join(file.path, file.name_with_extension)
      else
        file.name_with_extension
      end
    end

    def add_content_to_task_file(file, task_file)
      if file.native_file.present?
        file_content = file.read
        task_file.content = file_content
        task_file.used_by_grader = false
        task_file.binary = true
        task_file.mimetype = MimeMagic.by_magic(file_content).type
      else
        task_file.content = file.content
        task_file.used_by_grader = true
        task_file.binary = false
      end
    end
  end
end
