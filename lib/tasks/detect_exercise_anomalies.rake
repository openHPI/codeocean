# frozen_string_literal: true

namespace :detect_exercise_anomalies do
  # uncomment for debug logging:
  # logger           = Logger.new($stdout)
  # logger.level     = Logger::DEBUG
  # Rails.logger     = logger

  # rubocop:disable Lint/ConstantDefinitionInBlock Style/MutableConstant
  # These factors determine if an exercise is an anomaly, given the average working time (avg):
  # (avg * MIN_TIME_FACTOR) <= working_time <= (avg * MAX_TIME_FACTOR)
  MIN_TIME_FACTOR = 0.1
  MAX_TIME_FACTOR = 2

  # Determines how many users are picked from the best/average/worst performers of each anomaly for feedback
  NUMBER_OF_USERS_PER_CLASS = 10

  # Determines margin below which user working times will be considered data errors (e.g. copy/paste solutions)
  MIN_USER_WORKING_TIME = 0.0

  # Cache exercise working times, because queries are expensive and values do not change between collections
  # rubocop:disable Style/MutableConstant
  WORKING_TIME_CACHE = {}
  AVERAGE_WORKING_TIME_CACHE = {}
  # rubocop:enable Style/MutableConstant
  # rubocop:enable Lint/ConstantDefinitionInBlock

  task :with_at_least, %i[number_of_exercises number_of_users] => :environment do |_task, args|
    include TimeHelper

    number_of_exercises = args[:number_of_exercises]
    number_of_users = args[:number_of_users]

    log "Searching for exercise collections with at least #{number_of_exercises} exercises and #{number_of_users} users."
    # Get all exercise collections that have at least the specified amount of exercises and at least the specified
    # number of users AND are flagged for anomaly detection
    collections = get_collections(number_of_exercises, number_of_users)
    log "Found #{collections.length}."

    collections.each do |collection|
      log(collection, 1, '- ')
      anomalies = find_anomalies(collection)

      next unless anomalies.length.positive?

      notify_collection_author(collection, anomalies) unless collection.user.nil?
      notify_users(collection, anomalies)
      reset_anomaly_detection_flag(collection)
    end
    log 'Done.'
  end

  def log(message = '', indent_level = 0, prefix = '')
    puts(("\t" * indent_level) + "#{prefix}#{message}")
  end

  def get_collections(number_of_exercises, number_of_solutions)
    ExerciseCollection
      .where(use_anomaly_detection: true)
      .joins("join exercise_collection_items eci on exercise_collections.id = eci.exercise_collection_id
                            join
                              (select e.id
                               from exercises e
                                 join submissions s on s.exercise_id = e.id
                               group by e.id
                               having #{ExerciseCollection.sanitize_sql(['count(s.user_id) > ?', number_of_solutions])}
                              ) as exercises_with_submissions on exercises_with_submissions.id = eci.exercise_id")
      .group('exercise_collections.id')
      .having('count(exercises_with_submissions.id) > ?', number_of_exercises)
  end

  def collect_working_times(collection)
    working_times = {}
    collection.exercise_collection_items.order(:position).each do |eci|
      log(eci.exercise.title, 2, '> ')
      working_times[eci.exercise.id] = get_average_working_time(eci.exercise)
    end
    working_times
  end

  def find_anomalies(collection)
    working_times = collect_working_times(collection).compact
    if working_times.values.size.positive?
      average = working_times.values.sum / working_times.values.size
      return working_times.select do |_, working_time|
        working_time > average * MAX_TIME_FACTOR or working_time < average * MIN_TIME_FACTOR
      end
    end
    {}
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
    log("Sending E-Mail to author (#{collection.user.displayname} <#{collection.user.email}>)...", 2)
    UserMailer.exercise_anomaly_detected(collection, anomalies).deliver_now
  end

  def notify_users(collection, anomalies)
    by_id_and_type = proc {|u| {user_id: u[:user_id], user_type: u[:user_type]} }

    log('Sending E-Mails to best and worst performing users of each anomaly...', 2)
    anomalies.each do |exercise_id, average_working_time|
      log("Anomaly in exercise #{exercise_id} (avg: #{average_working_time} seconds):", 2)
      exercise = Exercise.find(exercise_id)
      users_to_notify = []

      users = {}
      methods = %i[performers_by_time performers_by_score]
      methods.each do |method|
        # merge users found by multiple methods returning a hash {best: [], worst: []}
        users = users.merge(send(method, exercise, NUMBER_OF_USERS_PER_CLASS)) {|_key, this, other| this + other }
      end

      # write reasons for feedback emails to db
      users.each_key do |key|
        segment = users[key].uniq(&by_id_and_type)
        users_to_notify += segment
        segment.each do |user|
          reason = "{\"segment\": \"#{key}\", \"feature\": \"#{user[:reason]}\", value: \"#{user[:value]}\"}"
          AnomalyNotification.create(user_id: user[:user_id], user_type: user[:user_type],
            exercise:, exercise_collection: collection, reason:)
        end
      end

      users_to_notify.uniq!(&by_id_and_type)
      users_to_notify.each do |u|
        user = u[:user_type] == InternalUser.name ? InternalUser.find(u[:user_id]) : ExternalUser.find(u[:user_id])
        host = CodeOcean::Application.config.action_mailer.default_url_options[:host]
        feedback_link = Rails.application.routes.url_helpers.url_for(action: :new,
          controller: :user_exercise_feedbacks, exercise_id: exercise.id, host:)
        UserMailer.exercise_anomaly_needs_feedback(user, exercise, feedback_link).deliver
      end
      log("Asked #{users_to_notify.size} users for feedback.", 2)
    end
  end

  def performers_by_score(exercise, users)
    submissions = exercise.last_submission_per_user.where.not(score: nil).order(score: :desc)
    map_block = proc {|item| {user_id: item.user_id, user_type: item.user_type, value: item.score, reason: 'score'} }
    best_performers = submissions.first(users).to_a.map(&map_block)
    worst_performers = submissions.last(users).to_a.map(&map_block)
    {best: best_performers, worst: worst_performers}
  end

  def performers_by_time(exercise, users)
    working_times = get_user_working_times(exercise).values.map do |item|
      {user_id: item['user_id'], user_type: item['user_type'], score: item['score'].to_f,
       value: time_to_f(item['working_time']), reason: 'time'}
    end
    avg_score = exercise.average_score
    working_times.reject! do |item|
      item[:value].nil? or item[:value] <= MIN_USER_WORKING_TIME or item[:score] < avg_score
    end
    working_times.sort_by! {|item| item[:value] }
    {best: working_times.first(users), worst: working_times.last(users)}
  end

  def reset_anomaly_detection_flag(collection)
    log('Resetting flag...', 2)
    collection.use_anomaly_detection = false
    collection.save!
  end
end
