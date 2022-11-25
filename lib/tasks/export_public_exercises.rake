# frozen_string_literal: true

namespace :export_exercises do
  desc 'exports all public exercises to codeharbor'
  task :public, [:codeharbor_link_id] => [:environment] do |_, args|
    codeharbor_link = CodeharborLink.find(args.codeharbor_link_id)
    successful_exports = []
    failed_exports = []
    Exercise.where(public: true).each do |exercise|
      puts "Exporting exercise ##{exercise.id}"
      error = ExerciseService::PushExternal.call(
        zip: ProformaService::ExportTask.call(exercise:),
        codeharbor_link:
      )
      if error.nil?
        successful_exports << exercise.id
        puts "Successfully exported exercise# #{exercise.id}"
      else
        failed_exports << exercise.id
        puts "An error occured during export of exercise# #{exercise.id}: #{error}"
      end
    end

    puts "successful exports: count: #{successful_exports.count} \nlist: #{successful_exports}"
    puts "failed exports: count: #{failed_exports.count} \nlist: #{failed_exports}"
  end
end
