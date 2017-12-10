namespace :detect_exercise_anomalies do

  task :with_at_least, [:number_of_exercises, :number_of_solutions] => :environment do |task, args|
    number_of_exercises = args.number_of_exercises
    number_of_solutions = args.number_of_solutions

    # These factors determine if an exercise is an anomaly, given the average working time (avg):
    # (avg * MIN_TIME_FACTOR) <= working_time <= (avg * MAX_TIME_FACTOR)
    MIN_TIME_FACTOR = 0.1
    MAX_TIME_FACTOR = 2

    # Get all exercise collections that have at least the specified amount of exercises and at least the specified
    # number of submissions AND are flagged for anomaly detection
    collections = ExerciseCollection
                      .where(:use_anomaly_detection => true)
                      .joins("join exercise_collections_exercises ece on exercise_collections.id = ece.exercise_collection_id
                              join
                                (select e.id
                                 from exercises e
                                   join submissions s on s.exercise_id = e.id
                                 group by e.id
                                 having count(s.user_id) > #{ExerciseCollection.sanitize(number_of_solutions)}
                                ) as exercises_with_submissions on exercises_with_submissions.id = ece.exercise_id")
                      .group('exercise_collections.id')
                      .having('count(exercises_with_submissions.id) > ?', number_of_exercises)

    collections.each do |collection|
      puts "\t- #{collection}"
      working_times = {}
      collection.exercises.each do |exercise|
        puts "\t\t> #{exercise.title}"
        avgwt = exercise.average_working_time.split(':')
        seconds = avgwt[0].to_i * 60 * 60 + avgwt[1].to_i * 60 + avgwt[2].to_f
        working_times[exercise.id] = seconds
      end
      average = working_times.values.reduce(:+) / working_times.size
      anomalies = working_times.select do |exercise_id, working_time|
        working_time > average * MAX_TIME_FACTOR or working_time < average * MIN_TIME_FACTOR
      end

      UserMailer.exercise_anomaly_detected(collection, anomalies).deliver_now
    end
  end

end
