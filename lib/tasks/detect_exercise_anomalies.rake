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

  # Determines how many contributors are picked from the best/average/worst performers of each anomaly for feedback
  NUMBER_OF_CONTRIBUTORS_PER_CLASS = 10

  # Determines margin below which contributor working times will be considered data errors (e.g. copy/paste solutions)
  MIN_CONTRIBUTOR_WORKING_TIME = 0.0

  # Cache exercise working times, because queries are expensive and values do not change between collections
  # rubocop:disable Style/MutableConstant
  WORKING_TIME_CACHE = {}
  AVERAGE_WORKING_TIME_CACHE = {}
  # rubocop:enable Style/MutableConstant
  # rubocop:enable Lint/ConstantDefinitionInBlock

  task :with_at_least, %i[number_of_exercises number_of_contributors] => :environment do |_task, args|
    include TimeHelper

    # Set intervalstyle to iso_8601 to avoid problems with time parsing.
    ApplicationRecord.connection.exec_query("SET intervalstyle = 'iso_8601';")

    number_of_exercises = args[:number_of_exercises]
    number_of_contributors = args[:number_of_contributors]

    log "Searching for exercise collections with at least #{number_of_exercises} exercises and #{number_of_contributors} contributors."
    # Get all exercise collections that have at least the specified amount of exercises and at least the specified
    # number of contributors AND are flagged for anomaly detection
    collections = get_collections(number_of_exercises, number_of_contributors)
    log "Found #{collections.length}."

    collections.each do |collection|
      log(collection, 1, '- ')
      anomalies = find_anomalies(collection)

      next unless anomalies.length.positive?

      notify_collection_author(collection, anomalies) unless collection.user.nil?
      notify_contributors(collection, anomalies)
      reset_anomaly_detection_flag(collection)
    end
    log 'Done.'
  end

  def log(message = '', indent_level = 0, prefix = '')
    puts(("\t" * indent_level) + "#{prefix}#{message}")
  end

  def get_collections(number_of_exercises, number_of_solutions)
    ExerciseCollection
      .joins(:exercises)
      .where(use_anomaly_detection: true)
      .where(
        exercises: Submission.from(
          Submission.group(:contributor_id, :contributor_type, :exercise_id)
                    .select(:contributor_id, :contributor_type, :exercise_id),
          'submissions'
        ).group(:exercise_id)
        .having('count(submissions.exercise_id) >= ?', number_of_solutions)
        .select(:exercise_id)
      ).group(:id)
      .having('count(exercises.id) >= ?', number_of_exercises)
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

  def get_contributor_working_times(exercise)
    unless WORKING_TIME_CACHE.key?(exercise.id)
      exercise.retrieve_working_time_statistics
      WORKING_TIME_CACHE[exercise.id] = exercise.working_time_statistics.flat_map do |contributor_type, contributor_id_with_result|
        contributor_id_with_result.flat_map do |contributor_id, result|
          {[contributor_type, contributor_id] => result}
        end
      end.inject(:merge)
    end
    WORKING_TIME_CACHE[exercise.id]
  end

  def notify_collection_author(collection, anomalies)
    log("Sending E-Mail to author (#{collection.user.displayname} <#{collection.user.email}>)...", 2)
    UserMailer.exercise_anomaly_detected(collection, anomalies).deliver_later
  end

  def notify_contributors(collection, anomalies)
    by_id_and_type = proc {|u| {contributor_id: u[:contributor_id], contributor_type: u[:contributor_type]} }

    log('Sending E-Mails to best and worst performing contributors of each anomaly...', 2)
    anomalies.each do |exercise_id, average_working_time|
      log("Anomaly in exercise #{exercise_id} (avg: #{average_working_time} seconds):", 2)
      exercise = Exercise.find(exercise_id)
      contributors_to_notify = []

      contributors = {}
      methods = %i[performers_by_time performers_by_score]
      methods.each do |method|
        # merge contributors found by multiple methods returning a hash {best: [], worst: []}
        contributors = contributors.merge(send(method, exercise, NUMBER_OF_CONTRIBUTORS_PER_CLASS)) {|_key, this, other| this + other }
      end

      # write reasons for feedback emails to db
      contributors.each_key do |key|
        segment = contributors[key].uniq(&by_id_and_type)
        contributors_to_notify += segment
        segment.each do |contributor|
          reason = {segment: key, feature: contributor[:reason], value: contributor[:value]}
          AnomalyNotification.create(contributor_id: contributor[:contributor_id], contributor_type: contributor[:contributor_type],
            exercise:, exercise_collection: collection, reason:)
        end
      end

      # send feedback emails
      # Potentially, a user that solved the exercise alone and as part of a study group is notified multiple times.
      contributors_to_notify.uniq!(&by_id_and_type)
      contributors_to_notify.each do |c|
        contributor = c[:contributor_type].constantize.find(c[:contributor_id])
        users = contributor.try(:users) || [contributor]
        users.each do |user|
          host = CodeOcean::Application.config.action_mailer.default_url_options[:host]
          last_submission = user.submissions.where(exercise:).latest
          token = AuthenticationToken.generate!(user, last_submission.study_group).shared_secret
          feedback_link = Rails.application.routes.url_helpers.url_for(action: :new,
            controller: :user_exercise_feedbacks, exercise_id: exercise.id, host:, token:)
          UserMailer.exercise_anomaly_needs_feedback(user, exercise, feedback_link).deliver
        end
      end
      log("Asked #{contributors_to_notify.size} contributors for feedback.", 2)
    end
  end

  def performers_by_score(exercise, contributors)
    submissions = exercise.last_submission_per_contributor.where.not(score: nil).order(score: :desc)
    map_block = proc {|item| {contributor_id: item.contributor_id, contributor_type: item.contributor_type, value: item.score, reason: 'score'} }
    best_performers = submissions.first(contributors).to_a.map(&map_block)
    worst_performers = submissions.last(contributors).to_a.map(&map_block)
    {best: best_performers, worst: worst_performers}
  end

  def performers_by_time(exercise, contributors)
    working_times = get_contributor_working_times(exercise).values.map do |item|
      {contributor_id: item['contributor_id'], contributor_type: item['contributor_type'], score: item['score'].to_f,
       value: time_to_f(item['working_time']), reason: 'time'}
    end
    avg_score = exercise.average_score
    working_times.reject! do |item|
      item[:value].nil? or item[:value] <= MIN_CONTRIBUTOR_WORKING_TIME or item[:score] < avg_score
    end
    working_times.sort_by! {|item| item[:value] }
    {best: working_times.first(contributors), worst: working_times.last(contributors)}
  end

  def reset_anomaly_detection_flag(collection)
    log('Resetting flag...', 2)
    collection.use_anomaly_detection = false
    collection.save!
  end
end
