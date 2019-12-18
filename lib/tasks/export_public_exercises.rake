# frozen_string_literal: true

namespace :export_exercises do
  desc 'exports all public exercises to codeharbor'
  task :public, [:codeharbor_link_id] => [:environment] do |_, args|
    codeharbor_link = CodeharborLink.find(args.codeharbor_link_id)

    Exercise.where(public: true).each do |exercise|
      puts "Exporting exercise\# #{exercise.id}"
      error = ExerciseService::PushExternal.call(
        zip: ProformaService::ExportTask.call(exercise: exercise),
        codeharbor_link: codeharbor_link
      )
      if error.nil?
        puts "Successfully exported exercise\# #{exercise.id}"
      else
        puts "An error occured during export of exercise\# #{exercise.id}: #{error}"
      end
    end
  end
end
