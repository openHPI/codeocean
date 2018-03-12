module Proforma
  class Importer

    def from_proforma_xml(exercise, xml)
      @exercise = exercise
      doc = Nokogiri::XML(xml)
      doc.collect_namespaces

      @exercise.attributes = {
          title: doc.xpath('/p:task/p:meta-data/p:title').text,
          description: doc.xpath('/p:task/p:description').text
      }
      prog_language = doc.xpath('/p:task/p:proglang').text
      version = doc.xpath('/p:task/p:proglang/@version').first.value
      exec_environment = ExecutionEnvironment.where(name: prog_language + ' ' + version).take
      if exec_environment
        exec_environment_id = exec_environment.id
      else
        exec_environment_id = 1
      end
      @exercise.execution_environment_id = exec_environment_id

      add_files_xml(doc)

      return @exercise
    end

    private
      def add_files_xml(xml)
        xml.xpath('/p:task/p:files/p:file').each do |file|
          metadata = get_file_metadata(file)
          role = determine_file_role_from_proforma_file(xml, metadata)
          feedback_message = xml.xpath("//p:test/p:test-configuration/p:filerefs/p:fileref[@refid='#{metadata[:file_id]}']/../../c:feedback-message").text
          filename = get_name_from_filename(metadata[:filename])
          if filename != ''
            @exercise.files.build({
                            content: file.text,
                            name: filename,
                            path: get_path_from_filename(metadata[:filename]),
                            file_type: get_filetype_from_filename(metadata[:filename]),
                            role: role,
                            feedback_message: (role == 'teacher_defined_test') ? feedback_message : nil,
                            hidden: metadata[:file_class] == 'internal',
                            read_only: false })
          end
        end
      end

      def get_file_metadata(file)
        file_id = file.xpath('@id').first.value
        file_class = file.xpath('@class').first.value
        comment = file.xpath('@comment').first.try(:value)
        filename = file.xpath('@filename').first
        {:file_id => file_id, :file_class => file_class, :comment => comment, :filename => filename}
      end

      def split_up_filename(filename)
        if filename.include? '/'
          name_with_type = filename.split(/\/(?=[^\/]*$)/).second
          path = filename.split(/\/(?=[^\/]*$)/).first
        else
          name_with_type = filename
          path = ''
        end
        if name_with_type.include? '.'
          name  = name_with_type.split('.').first
          type = name_with_type.split('.').second
        else
          name = name_with_type
          type = ''
        end
        return path, name, type
      end

      def get_filetype_from_filename(filename_attribute)

        if filename_attribute
          type = split_up_filename(filename_attribute.value).third
          if type != ''
            return FileType.find_by(file_extension: ".#{type}")
          end
        end
        return FileType.find_by(name: 'Makefile')
      end

      def get_name_from_filename(filename_attribute)

        if filename_attribute
          name = split_up_filename(filename_attribute.value).second
          return name
        else
          ''
        end
      end

      def get_path_from_filename(filename_attribute)

        if filename_attribute
          path = split_up_filename(filename_attribute.value).first
        end
        ''
      end

      def determine_file_role_from_proforma_file(xml, metadata)
        if teacher_defined_test?(xml, metadata)
          'teacher_defined_test'
        elsif reference_implementation?(xml, metadata)
          'reference_implementation'
        elsif main_file?(metadata)
          'main_file'
        elsif no_role?(metadata)
          ''
        else
          'regular_file'
        end
      end

      def teacher_defined_test?(xml, metadata)
        is_referenced_by_test = xml.xpath("//p:test/p:test-configuration/p:filerefs/p:fileref[@refid='#{metadata[:file_id]}']")
        is_referenced_by_test.any? && (metadata[:file_class] == 'internal')
      end

      def reference_implementation?(xml, metadata)
        is_referenced_by_model_solution = xml.xpath("//p:model-solution/p:filerefs/p:fileref[@refid='#{metadata[:file_id]}']")
        is_referenced_by_model_solution.any? && (metadata[:file_class] == 'internal')
      end

      def main_file?(metadata)
        (metadata[:file_class] == 'template') && (metadata[:comment] == 'main')
      end

      def no_role?(metadata)
        (metadata[:file_class] == 'internal') && (metadata[:comment] == 'main')
      end
  end
end