namespace :detect_exercise_anomalies do

  # These factors determine if an exercise is an anomaly, given the average working time (avg):
  # (avg * MIN_TIME_FACTOR) <= working_time <= (avg * MAX_TIME_FACTOR)
  MIN_TIME_FACTOR = 0.1
  MAX_TIME_FACTOR = 2

  task :with_at_least, [:number_of_exercises, :number_of_solutions] => :environment do |task, args|
    number_of_exercises = args[:number_of_exercises]
    number_of_solutions = args[:number_of_solutions]

    puts "Searching for exercise collections with at least #{number_of_exercises} exercises and #{number_of_solutions} users."
    # Get all exercise collections that have at least the specified amount of exercises and at least the specified
    # number of submissions AND are flagged for anomaly detection
    collections = get_collections(number_of_exercises, number_of_solutions)
    puts "Found #{collections.length}."

    collections.each do |collection|
      puts "\t- #{collection}"
      anomalies = find_anomalies(collection)

      if anomalies.length > 0 and not collection.user.nil?
        puts "\t\tAnomalies: #{anomalies}\n"
        notify_collection_author(collection, anomalies)
        notify_users(collection, anomalies)
        reset_anomaly_detection_flag(collection)
      end
    end
    puts 'Done.'
  end

  def get_collections(number_of_exercises, number_of_solutions)
    ExerciseCollection
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
  end

  def find_anomalies(collection)
    working_times = {}
    collection.exercises.each do |exercise|
      puts "\t\t> #{exercise.title}"
      avgwt = exercise.average_working_time.split(':')
      seconds = avgwt[0].to_i * 60 * 60 + avgwt[1].to_i * 60 + avgwt[2].to_f
      working_times[exercise.id] = seconds
    end
    average = working_times.values.reduce(:+) / working_times.size
    working_times.select do |exercise_id, working_time|
      working_time > average * MAX_TIME_FACTOR or working_time < average * MIN_TIME_FACTOR
    end
  end

  def notify_collection_author(collection, anomalies)
    puts "\t\tSending E-Mail to author (#{collection.user.displayname} <#{collection.user.email}>)..."
    UserMailer.exercise_anomaly_detected(collection, anomalies).deliver_now
  end

  def notify_users(collection, anomalies)
    puts "\t\tSending E-Mails to best and worst performing users of each anomaly..."
    anomalies.each do |exercise_id, average_working_time|
      submissions = Submission.find_by_sql(['
            select distinct s.*
            from
              (
                select
                    user_id,
                    first_value(id) over (partition by user_id order by created_at desc) as fv
                from submissions
                where exercise_id = ?
              ) as t
              join submissions s on s.id = t.fv
            where score is not null
            order by score', exercise_id])
      best_performers = submissions.first(10).to_a.map do |item|
        item.user_id
      end
      worst_performers = submissions.last(10).to_a.map do |item|
        item.user_id
      end
      puts "\t\tAnomaly in exercise #{exercise_id}:"
      puts "\t\t\tbest performers: #{best_performers}"
      puts "\t\t\tworst performers: #{worst_performers}"
    end
  end

  def reset_anomaly_detection_flag(collection)
    puts "\t\tResetting flag..."
    collection.use_anomaly_detection = false
    collection.save!
  end

end
