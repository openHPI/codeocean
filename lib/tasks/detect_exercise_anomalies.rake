namespace :detect_exercise_anomalies do

  # These factors determine if an exercise is an anomaly, given the average working time (avg):
  # (avg * MIN_TIME_FACTOR) <= working_time <= (avg * MAX_TIME_FACTOR)
  MIN_TIME_FACTOR = 0.1
  MAX_TIME_FACTOR = 2

  # Determines how many users are picked from the best/average/worst performers of each anomaly for feedback
  NUMBER_OF_USERS_PER_CLASS = 10

  # Determines margin below which user working times will be considered data errors (e.g. copy/paste solutions)
  MIN_USER_WORKING_TIME = 0.0

  # Cache exercise working times, because queries are expensive and values do not change between collections
  WORKING_TIME_CACHE = {}
  AVERAGE_WORKING_TIME_CACHE = {}

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
      working_times[exercise.id] = get_average_working_time(exercise)
    end
    average = working_times.values.reduce(:+) / working_times.size
    working_times.select do |exercise_id, working_time|
      working_time > average * MAX_TIME_FACTOR or working_time < average * MIN_TIME_FACTOR
    end
  end

  def time_to_f(timestamp)
    unless timestamp.nil?
      timestamp = timestamp.split(':')
      return timestamp[0].to_i * 60 * 60 + timestamp[1].to_i * 60 + timestamp[2].to_f
    end
    nil
  end

  def get_average_working_time(exercise)
    unless AVERAGE_WORKING_TIME_CACHE.key?(exercise.id)
      seconds = time_to_f exercise.average_working_time
      AVERAGE_WORKING_TIME_CACHE[exercise.id] = seconds
    end
    AVERAGE_WORKING_TIME_CACHE[exercise.id]
  end

  def get_user_working_times(exercise)
    unless WORKING_TIME_CACHE.key?(exercise.id)
      exercise.retrieve_working_time_statistics
      WORKING_TIME_CACHE[exercise.id] = exercise.working_time_statistics
    end
    WORKING_TIME_CACHE[exercise.id]
  end

  def notify_collection_author(collection, anomalies)
    puts "\t\tSending E-Mail to author (#{collection.user.displayname} <#{collection.user.email}>)..."
    UserMailer.exercise_anomaly_detected(collection, anomalies).deliver_now
  end

  def notify_users(collection, anomalies)
    puts "\t\tSending E-Mails to best and worst performing users of each anomaly..."
    anomalies.each do |exercise_id, average_working_time|
      puts "\t\tAnomaly in exercise #{exercise_id} (avg: #{average_working_time} seconds):"
      exercise = Exercise.find(exercise_id)
      users_to_notify = []

      users = {}
      [:performers_by_time, :performers_by_score].each do |method|
        # merge users found by multiple methods returning a hash {best: [], worst: []}
        users = users.merge(send(method, exercise, NUMBER_OF_USERS_PER_CLASS)) {|key, this, other| this + other}
      end

      users.keys.each do |key|
        segment = users[key].uniq
        puts "\t\t\t#{key.to_s} performers: #{segment}"
        users_to_notify += segment
      end

      users_to_notify.uniq!
      # todo: send emails
    end
  end

  def performers_by_score(exercise, n)
    submissions = exercise.last_submission_per_user.where('score is not null').order(:score)
    best_performers = submissions.first(n).to_a.map {|item| item.user_id}
    worst_performers = submissions.last(n).to_a.map {|item| item.user_id}

    return {:best => best_performers, :worst => worst_performers}
  end

  def performers_by_time(exercise, n)
    working_times = get_user_working_times(exercise).values.map do |item|
      {user_id: item['user_id'], time: time_to_f(item['working_time'])}
    end
    working_times.reject! {|item| item[:time].nil? or item[:time] <= MIN_USER_WORKING_TIME}
    working_times.sort_by! {|item| item[:time]}

    working_times.map! {|item| item[:user_id].to_i}
    return {:best => working_times.first(n), :worst => working_times.last(n)}
  end

  def reset_anomaly_detection_flag(collection)
    puts "\t\tResetting flag..."
    collection.use_anomaly_detection = false
    collection.save!
  end

end
