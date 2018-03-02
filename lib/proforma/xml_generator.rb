require 'nokogiri'

module Proforma
  class XmlGenerator


    def generate_xml(exercise)
      @exercise = exercise
      xml = to_proforma_xml
      return xml
    end

    def build_proforma_xml_for_head(xml)
      proforma = xml['p']
      proforma.description {
        proforma.cdata(@exercise.description)
      }
      execution_environment = @exercise.execution_environment.name.split
      proforma.proglang(execution_environment.first, 'version' => execution_environment.second)
      proforma.send('submission-restrictions') {
        proforma.send('files-restriction') {
          proforma.send('optional', 'filename' => '')
        }
      }
    end

    def build_proforma_xml_for_single_file(xml, file)
      if file.role == 'main_file'
        proforma_file_class = 'template'
        comment = 'main'
      else
        proforma_file_class = 'internal'
        comment = ''
      end
      xml['p'].file(
          'filename' => file.full_file_name,
          'id' => file.id,
          'class' => proforma_file_class,
          'comment' => comment
      ) {
        xml.cdata(file.content)
      }
    end

    def build_proforma_xml_for_exercise_files(xml)
      proforma = xml['p']
      proforma.files {
        @exercise.files.all? { |file|
          build_proforma_xml_for_single_file(xml, file)
        }

        ### Set Placeholder file for placeholder solution-file and tests if there aren't any
        if model_solution_files.blank?
          proforma.file('', 'id' => '0', 'class' => 'internal')
        end
      }
    end

    def build_proforma_xml_for_tests(xml)
      proforma = xml['p']
      proforma.tests {
        tests.each_with_index { |test, index|
          proforma.test('id' => 't' + index.to_s) {
            proforma.title('')
            proforma.send('test-type', 'unittest')
            proforma.send('test-configuration') {
              proforma.filerefs {
                proforma.fileref('refid' => test.id.to_s)
              }
              xml['u'].unittest('framework' => testing_framework.first, 'version' => testing_framework.second)
              xml['c'].send('feedback-message') {
                xml.cdata(test.feedback_message)
              }
            }
          }
        }
      }
    end

    def build_proforma_xml_for_model_solutions(xml)
      proforma = xml['p']
      proforma.send('model-solutions') {
        if model_solution_files.any?
          model_solution_files.each_with_index { |model_solution_file, index|
            proforma = xml['p']
            proforma.send('model-solution', 'id' => 'm' + index.to_s) {
              proforma.filerefs {
                proforma.fileref('refid' => model_solution_file.id.to_s)
              }
            }
          }
        else ##Placeholder solution_file if there aren't any
          proforma.send('model-solution', 'id' => 'm0') {
            proforma.filerefs {
              proforma.fileref('refid' => '0')
            }
          }
        end
      }
    end

    def testing_framework
      case @exercise.execution_environment.testing_framework
        when 'RspecAdapter'
          return 'Rspec', ''
        when 'JunitAdapter'
          return 'JUnit', '4'
        when 'PyUnitAdapter'
          return 'PyUnit', ''
        else
          return '', ''
      end
    end

    def to_proforma_xml
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        proforma = xml['p']
        proforma.task('xmlns:p' => 'urn:proforma:task:v1.1', 'lang' => 'de', 'uuid' => SecureRandom.uuid,
                      'xmlns:u' => 'urn:proforma:tests:unittest:v1.1', 'xmlns:c' => 'codeharbor'){
          build_proforma_xml_for_head(xml)
          build_proforma_xml_for_exercise_files(xml)
          build_proforma_xml_for_model_solutions(xml)
          build_proforma_xml_for_tests(xml)
          #xml['p'].send('grading-hints', 'max-rating' => @exercise.maxrating.to_s)
          proforma.send('meta-data') {
            proforma.title(@exercise.title)
          }
        }
      end
      return builder.to_xml
    end

    def model_solution_files
      @exercise.files.where(role: 'reference_implementation')
    end

    def tests
      @exercise.files.where(role: 'teacher_defined_test')
    end
  end
end