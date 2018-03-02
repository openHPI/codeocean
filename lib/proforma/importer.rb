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

    def add_files_xml(xml)
      xml.xpath('/p:task/p:files/p:file').each do |file|
        role = determine_file_role_from_proforma_file(xml, file)
        filename_attribute = file.xpath('@filename').first
        if filename_attribute
          filename = filename_attribute.value
          if filename.include? '/'
            path_name_split = filename.split (/\/(?=[^\/]*$)/)
            path = path_name_split.first
            name_with_type = path_name_split.second
          else
            path = ''
            name_with_type = filename
          end
          if name_with_type.include? '.'
            name_type_split = name_with_type.split('.')
            name = name_type_split.first
            type = name_type_split.second
          else
            name = name_with_type
            type = ''
          end
        else
          path = ''
          name = ''
          type = ''
        end

        file_id = file.xpath('@id').first.value
        file_class = file.xpath('@class').first.value
        content = file.text
        feedback_message = xml.xpath("//p:test/p:test-configuration/p:filerefs/p:fileref[@refid='#{file_id}']/../../c:feedback-message").text
        @exercise.files.build({
                        content: content,
                        name: name,
                        path: path,
                        file_type: FileType.find_by(file_extension: ".#{type}"),
                        role: role,
                        feedback_message: (role == 'teacher_defined_test') ? feedback_message : nil,
                        hidden: file_class == 'internal',
                        read_only: false })
      end
    end

    def determine_file_role_from_proforma_file(xml, file)
      file_id = file.xpath('@id').first.value
      file_class = file.xpath('@class').first.value
      comment = file.xpath('@comment').first.try(:value)
      is_referenced_by_test = xml.xpath("//p:test/p:test-configuration/p:filerefs/p:fileref[@refid='#{file_id}']")
      is_referenced_by_model_solution = xml.xpath("//p:model-solution/p:filerefs/p:fileref[@refid='#{file_id}']")
      if !is_referenced_by_test.empty? && (file_class == 'internal')
        return 'teacher_defined_test'
      elsif !is_referenced_by_model_solution.empty? && (file_class == 'internal')
        return 'reference_implementation'
      elsif (file_class == 'template') && (comment == 'main')
        return 'main_file'
      elsif (file_class == 'internal') && (comment == 'main')
      end
      return 'regular_file'
    end
  end
end