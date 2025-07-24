# frozen_string_literal: true

class Exercise < ApplicationRecord
  include Context
  include Creation
  include DefaultValues
  include TimeHelper
  include RansackObject

  after_initialize :generate_token
  after_initialize :set_default_values

  belongs_to :execution_environment, optional: true
  has_many :submissions

  has_many :anomaly_notifications, as: :contributor, dependent: :destroy
  has_and_belongs_to_many :proxy_exercises
  has_many :user_proxy_exercise_exercises
  has_many :exercise_collection_items, dependent: :delete_all
  has_many :exercise_collections, through: :exercise_collection_items, inverse_of: :exercises
  has_many :user_exercise_interventions
  has_many :interventions, through: :user_exercise_interventions
  has_many :exercise_tags
  has_many :tags, through: :exercise_tags
  accepts_nested_attributes_for :exercise_tags
  has_many :user_exercise_feedbacks
  has_many :pair_programming_exercise_feedbacks
  has_many :exercise_tips
  has_many :tips, through: :exercise_tips

  has_many :external_users, source: :contributor, source_type: 'ExternalUser', through: :submissions
  has_many :internal_users, source: :contributor, source_type: 'InternalUser', through: :submissions
  has_many :programming_groups
  has_many :pair_programming_waiting_users
  has_many :request_for_comments
  has_many :study_groups, through: :submissions

  validate :valid_main_file?
  validate :valid_submission_deadlines?
  validates :description, presence: true
  validates :execution_environment, presence: true, if: -> { !unpublished? }
  validates :public, inclusion: [true, false]
  validates :unpublished, inclusion: [true, false]
  validates :title, presence: true
  validates :token, presence: true, uniqueness: true
  validates :uuid, uniqueness: {if: -> { uuid.present? }}

  delegate :to_s, to: :title

  @working_time_statistics = nil
  attr_reader :working_time_statistics

  MAX_GROUP_EXERCISE_FEEDBACKS = 20

  def average_percentage(base = submissions)
    if average_score(base) && (maximum_score.to_d != BigDecimal('0.0')) && base.exists?(cause: %w[submit assess remoteSubmit remoteAssess])
      (average_score(base) / maximum_score * 100).round(2)
    else
      0
    end
  end

  def finishers_percentage
    if contributors.empty?
      0
    else
      (100.0 / contributors.size * finishers_count).round(2)
    end
  end

  def average_score(base = submissions)
    Submission.from(
      base.group(:contributor_id, :contributor_type)
                 .select('MAX(score) as max_score')
    ).average(:max_score).to_f
  end

  def average_number_of_submissions
    contributors.empty? ? 0 : submissions.count / contributors.size.to_f
  end

  def contributors
    @contributors ||= internal_users.distinct + external_users.distinct + programming_groups.distinct
  end

  def time_maximum_score(contributor)
    submissions
      .where(contributor:, cause: %w[submit assess remoteSubmit remoteAssess])
      .where.not(score: nil)
      .order(score: :desc, created_at: :asc)
      .first&.created_at || Time.zone.at(0)
  end

  def user_working_time_query
    "
      SELECT contributor_id,
             contributor_type,
             SUM(working_time_new) AS working_time,
             MAX(score) AS score
      FROM
        (SELECT contributor_id,
                contributor_type,
                score,
                CASE WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0' ELSE working_time END AS working_time_new
         FROM
            (SELECT contributor_id,
                    contributor_type,
                    score,
                    id,
                    (created_at - lag(created_at) over (PARTITION BY contributor_id, exercise_id
                                                        ORDER BY created_at)) AS working_time
            FROM submissions
            WHERE #{self.class.sanitize_sql(['exercise_id = ?', id])}) AS foo) AS bar
      GROUP BY contributor_id, contributor_type
    "
  end

  def study_group_working_time_query(exercise_id, study_group_id, additional_filter)
    "
    WITH exercises_with_maximum_score AS (
      SELECT exercises.id,
             COALESCE(SUM(files.weight) FILTER (WHERE files.role IN ('teacher_defined_test', 'teacher_defined_linter')), 0) AS exercise_maximum_score
      FROM exercises
      LEFT JOIN files
        ON files.context_id = exercises.id AND files.context_type = 'Exercise'
      GROUP BY exercises.id
    ),
    working_time_between_submissions AS (
      SELECT contributor_id,
             contributor_type,
             exercise_id,
             score,
             created_at,
             -- the `working_time` specifies the time taken between the current submission and the NEXT one.
             (lag(created_at) OVER (PARTITION BY contributor_type, contributor_id, exercise_id
                 ORDER BY created_at DESC) - created_at) AS working_time
      FROM submissions
      WHERE #{self.class.sanitize_sql(['exercise_id = ? and study_group_id = ?', exercise_id, study_group_id])} #{self.class.sanitize_sql(additional_filter)}
    ),
    working_time_with_deltas_ignored AS (
      SELECT contributor_id,
             contributor_type,
             exercise_id,
             score,
             sum(CASE WHEN score IS NOT NULL THEN 1 ELSE 0 END)
                 OVER (ORDER BY contributor_type, contributor_id, exercise_id, created_at ASC) AS potential_change_in_score,
             created_at,
             CASE WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0' ELSE working_time END AS working_time_filtered
      FROM working_time_between_submissions
    ),
    working_times_with_score_expanded AS (
      SELECT contributor_id,
             contributor_type,
             exercise_id,
             coalesce(first_value(score)
                 OVER (PARTITION BY contributor_type, contributor_id, exercise_id, potential_change_in_score
                 ORDER BY created_at ASC), 0) AS corrected_score,
             exercise_maximum_score,
             created_at,
             working_time_filtered
      FROM working_time_with_deltas_ignored
      JOIN exercises_with_maximum_score
        ON exercises_with_maximum_score.id = working_time_with_deltas_ignored.exercise_id
    ),
    earliest_max_score AS (
      SELECT contributor_id, contributor_type, exercise_id,
             -- earliest_high_score_time is NULL if maximum score not reached.
             MIN(MIN(created_at) FILTER (WHERE corrected_score = exercise_maximum_score))
                 OVER (PARTITION BY contributor_id, contributor_type, exercise_id) AS earliest_max_score_time
      FROM working_times_with_score_expanded
      GROUP BY contributor_id, contributor_type, exercise_id
    ),
    working_times_until_high_score AS (
      SELECT working_times_with_score_expanded.contributor_id,
             working_times_with_score_expanded.contributor_type,
             working_times_with_score_expanded.exercise_id,
             coalesce(corrected_score != lag(corrected_score) OVER
                 (PARTITION BY working_times_with_score_expanded.contributor_id, working_times_with_score_expanded.contributor_type, working_times_with_score_expanded.exercise_id
                 ORDER BY created_at ASC), false) AS score_changed,
             corrected_score AS score,
             exercise_maximum_score,
             CASE WHEN corrected_score = exercise_maximum_score THEN true ELSE false END AS is_maximum_score,
             created_at,
             working_time_filtered
      FROM working_times_with_score_expanded
      JOIN earliest_max_score
        ON working_times_with_score_expanded.contributor_id = earliest_max_score.contributor_id AND
           working_times_with_score_expanded.contributor_type = earliest_max_score.contributor_type AND
           working_times_with_score_expanded.exercise_id = earliest_max_score.exercise_id
      WHERE earliest_max_score_time IS NULL OR created_at <= earliest_max_score_time
    ),
    working_times_with_change AS (
      SELECT contributor_id,
             contributor_type,
             exercise_id,
             score,
             SUM(score_changed::int) OVER (ORDER BY contributor_id, contributor_type, exercise_id, created_at) AS change_in_score,
             exercise_maximum_score,
             is_maximum_score,
             created_at,
             working_time_filtered
      FROM working_times_until_high_score
    ),
    total_working_times AS (
      SELECT contributor_id,
             contributor_type,
             exercise_id,
             score,
             exercise_maximum_score,
             is_maximum_score,
             -- the highest score reached the latest is the final score.
             -- If the highest score is the maximum score, only one occurrence is expected (which is the final score).
             lead(false, 1, true)
                 OVER (PARTITION BY exercise_id, contributor_type, contributor_id ORDER BY score ASC, MIN(created_at) ASC) AS is_final_score,
             MIN(created_at) AS start_time,
             COALESCE(SUM(working_time_filtered)
                 FILTER (WHERE NOT is_maximum_score), '00:00:00') AS working_time_per_score,
             COALESCE(SUM(SUM(working_time_filtered))
                 FILTER (WHERE NOT is_maximum_score)
                 OVER (PARTITION BY contributor_id, contributor_type, exercise_id),'00:00:00') AS total_working_time
      FROM working_times_with_change
      GROUP BY contributor_id, contributor_type, exercise_id, score, change_in_score, exercise_maximum_score, is_maximum_score
    ),
    grouped_scores AS (
      SELECT contributor_id,
             contributor_type,
             exercise_id,
             score,
             exercise_maximum_score,
             is_maximum_score,
             BOOL_OR(is_final_score) AS is_final_score,
             MIN(start_time) AS start_time,
             SUM(working_time_per_score) AS working_time_per_score,
             total_working_time
      FROM total_working_times
      GROUP BY contributor_id, contributor_type, exercise_id, score, exercise_maximum_score, is_maximum_score, total_working_time
      ORDER BY exercise_id, contributor_id, contributor_type, score ASC
    ),
    total_working_times_with_index AS (
      SELECT (dense_rank() OVER (PARTITION BY exercise_id ORDER BY total_working_time, contributor_type, contributor_id ASC) - 1) AS index,
             *
      FROM grouped_scores
    )
    SELECT index,
           contributor_id,
           contributor_type,
           name,
           exercise_id,
           exercise_maximum_score,
           score,
           is_maximum_score,
           is_final_score,
           start_time,
           working_time_per_score,
           total_working_time
    FROM total_working_times_with_index
    JOIN external_users
      ON contributor_type = 'ExternalUser' AND
         contributor_id = external_users.id
    UNION ALL
    SELECT index,
           contributor_id,
           contributor_type,
           name,
           exercise_id,
           exercise_maximum_score,
           score,
           is_maximum_score,
           is_final_score,
           start_time,
           working_time_per_score,
           total_working_time
    FROM total_working_times_with_index
    JOIN internal_users
      ON contributor_type = 'InternalUser' AND
         contributor_id = internal_users.id
    UNION ALL
    SELECT index,
           contributor_id,
           contributor_type,
           concat('PG ', programming_groups.id::varchar) AS name,
           total_working_times_with_index.exercise_id,
           exercise_maximum_score,
           score,
           is_maximum_score,
           is_final_score,
           start_time,
           working_time_per_score,
           total_working_time
    FROM total_working_times_with_index
    JOIN programming_groups
      ON contributor_type = 'ProgrammingGroup' AND
         contributor_id = programming_groups.id
    ORDER BY exercise_id, index, score ASC;
    "
  end

  def teacher_defined_assessment?
    files.any?(&:teacher_defined_assessment?)
  end

  def get_working_times_for_study_group(study_group_id, user = nil)
    user_progress = []
    additional_user_data = []
    max_bucket = 100
    maximum_score = self.maximum_score

    additional_filter = if user.blank?
                          ''
                        else
                          "AND contributor_id = #{user.id} AND contributor_type = '#{user.class.name}'"
                        end

    results = self.class.connection.exec_query(study_group_working_time_query(id, study_group_id,
      additional_filter)).each do |tuple|
      bucket = if maximum_score > 0.0 && tuple['score'] <= maximum_score
                 (tuple['score'] / maximum_score * max_bucket).round
               else
                 max_bucket # maximum_score / maximum_score will always be 1
               end

      user_progress[bucket] ||= []
      additional_user_data[bucket] ||= []
      additional_user_data[max_bucket + 1] ||= []

      # TODO: Buckets might be overwritten, causing wrong data to be displayed.
      # The SQL query is correct (despite interventions missing, which are shown for regular external user statistics)!
      user_progress[bucket][tuple['index']] = format_time_difference(tuple['working_time_per_score'])
      additional_user_data[bucket][tuple['index']] = {start_time: tuple['start_time'], score: tuple['score']}
      additional_user_data[max_bucket + 1][tuple['index']] =
        {id: tuple['contributor_id'], type: tuple['contributor_type'], name: ERB::Util.html_escape(tuple['name'])}
    end

    if results.size.positive?
      first_index = results[0]['index']
      last_index = results[results.size - 1]['index']
      buckets = last_index - first_index
      user_progress.each do |timings_array|
        timings_array[buckets] = nil if timings_array.present? && timings_array.length != buckets + 1
      end
    end

    {user_progress:, additional_user_data:}
  end

  def get_quantiles(quantiles)
    result = self.class.connection.exec_query("
            WITH working_time AS
      (
               SELECT   contributor_id,
                        contributor_type,
                        created_at,
                        exercise_id,
                        Max(score)                                                                                  AS max_score,
                        (created_at - Lag(created_at) OVER (partition BY contributor_id, exercise_id ORDER BY created_at)) AS working_time
               FROM     submissions
               WHERE    #{self.class.sanitize_sql(['exercise_id = ?', id])}
               GROUP BY contributor_id,
                        contributor_type,
                        id,
                        exercise_id), max_points AS
      (
               SELECT   context_id  AS ex_id,
                        Sum(weight) AS max_points
               FROM     files
               WHERE    context_type = 'Exercise'
               AND      #{self.class.sanitize_sql(['context_id = ?', id])}
               AND      role IN ('teacher_defined_test', 'teacher_defined_linter')
               GROUP BY context_id),
      -- filter for rows containing max points
      time_max_score AS
      (
             SELECT *
             FROM   working_time W1,
                    max_points MS
             WHERE  w1.exercise_id = ex_id
             AND    w1.max_score = ms.max_points),
      -- find row containing the first time max points
      first_time_max_score AS
      (
             SELECT created_at,
                    contributor_id,
                    contributor_type,
                    exercise_id,
                    max_score,
                    working_time,
                    rn
             FROM   (
                             SELECT   created_at,
                                      contributor_id,
                                      contributor_type,
                                      exercise_id,
                                      max_score,
                                      working_time,
                                      Row_number() OVER(partition BY contributor_id, contributor_type, exercise_id ORDER BY created_at ASC) AS rn
                             FROM     time_max_score) T
             WHERE  rn = 1), times_until_max_points AS
      (
             SELECT w.created_at,
                    w.contributor_id,
                    w.contributor_type,
                    w.exercise_id,
                    w.max_score,
                    w.working_time,
                    m.created_at AS reachedmax_at
             FROM   working_time W,
                    first_time_max_score M
             WHERE  w.contributor_id = m.contributor_id
             AND    w.contributor_type = m.contributor_type
             AND    w.exercise_id = m.exercise_id
             AND    w.created_at <= m.created_at),
      -- if user never makes it to max points, take all times
      all_working_times_until_max AS (
      (
             SELECT created_at,
                    contributor_id,
                    contributor_type,
                    exercise_id,
                    max_score,
                    working_time
             FROM   times_until_max_points)
      UNION ALL
                (
                       SELECT created_at,
                              contributor_id,
                              contributor_type,
                              exercise_id,
                              max_score,
                              working_time
                       FROM   working_time W1
                       WHERE  NOT EXISTS
                              (
                                     SELECT 1
                                     FROM   first_time_max_score F
                                     WHERE  f.contributor_id = w1.contributor_id
                                     AND    f.contributor_type = w1.contributor_type
                                     AND    f.exercise_id = w1.exercise_id))), filtered_times_until_max AS
      (
             SELECT contributor_id,
                    contributor_type,
                    exercise_id,
                    max_score,
                    CASE
                           WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0'
                           ELSE working_time
                    END AS working_time_new
             FROM   all_working_times_until_max ), result AS
      (
               SELECT   contributor_id,
                        contributor_type,
                        exercise_id,
                        Max(max_score)        AS max_score,
                        Sum(working_time_new) AS working_time
               FROM     filtered_times_until_max
               GROUP BY contributor_id,
                        contributor_type,
                        exercise_id )
      SELECT   unnest(percentile_cont(#{self.class.sanitize_sql(['array[?]', quantiles])}) within GROUP (ORDER BY working_time))
      FROM     result
      ")
    if result.any?
      quantiles.each_with_index.map {|_q, i| parse_duration(result[i]['unnest']).to_f }
    else
      quantiles.map {|_q| 0 }
    end
  end

  def retrieve_working_time_statistics
    @working_time_statistics = {'InternalUser' => {}, 'ExternalUser' => {}, 'ProgrammingGroup' => {}}
    self.class.connection.exec_query(user_working_time_query).each do |tuple|
      tuple = tuple.merge('working_time' => format_time_difference(tuple['working_time']))
      @working_time_statistics[tuple['contributor_type']][tuple['contributor_id'].to_i] = tuple
    end
  end

  def average_working_time
    result = self.class.connection.exec_query("
      SELECT avg(working_time) as average_time
      FROM
        (#{self.class.sanitize_sql(user_working_time_query)}) AS baz;
    ").first['average_time']
    format_time_difference(result)
  end

  def average_working_time_for(user)
    retrieve_working_time_statistics if @working_time_statistics.nil?
    @working_time_statistics[user.class.name][user.id]['working_time']
  end

  def accumulated_working_time_for_only(contributor)
    submission_filter = {id:, contributor_id: contributor.id, contributor_type: contributor.class.name}
    begin
      result = self.class.connection.exec_query("
              WITH WORKING_TIME AS
              (SELECT contributor_id,
                                 contributor_type,
                                 created_at,
                                 exercise_id,
                                 max(score) AS max_score,
                                 (created_at - lag(created_at) OVER (PARTITION BY contributor_id, contributor_type, exercise_id
                                                                     ORDER BY created_at)) AS working_time
                         FROM submissions
                         WHERE #{self.class.sanitize_sql(['exercise_id = :id AND contributor_id = :contributor_id AND contributor_type = :contributor_type', submission_filter])}
                         GROUP BY contributor_id, contributor_type, created_at, exercise_id),
              MAX_POINTS AS
              (SELECT context_id AS ex_id, sum(weight) AS max_points FROM files WHERE context_type = 'Exercise' AND context_id = #{id} AND role IN ('teacher_defined_test', 'teacher_defined_linter') GROUP BY context_id),

              -- filter for rows containing max points
              TIME_MAX_SCORE AS
              (SELECT *
              FROM WORKING_TIME W1, MAX_POINTS MS
              WHERE W1.exercise_id = ex_id AND W1.max_score = MS.max_points),

              -- find row containing the first time max points
              FIRST_TIME_MAX_SCORE AS
              ( SELECT created_at, contributor_id, contributor_type, exercise_id, max_score, working_time, rn
                FROM (
                  SELECT created_at, contributor_id, contributor_type, exercise_id, max_score, working_time,
                      ROW_NUMBER() OVER(PARTITION BY contributor_id, contributor_type, exercise_id ORDER BY created_at ASC) AS rn
                  FROM TIME_MAX_SCORE) T
               WHERE rn = 1),

              TIMES_UNTIL_MAX_POINTS AS (
                  SELECT W.created_at, W.contributor_id, W.contributor_type, W.exercise_id, W.max_score, W.working_time, M.created_at AS reachedmax_at
                  FROM WORKING_TIME W, FIRST_TIME_MAX_SCORE M
                  WHERE W.contributor_id = M.contributor_id AND W.contributor_type = M.contributor_type AND W.exercise_id = M.exercise_id AND W.created_at <= M.created_at),

              -- if contributor never makes it to max points, take all times
              ALL_WORKING_TIMES_UNTIL_MAX AS
              ((SELECT created_at, contributor_id, contributor_type, exercise_id, max_score, working_time FROM TIMES_UNTIL_MAX_POINTS)
              UNION ALL
              (SELECT created_at, contributor_id, contributor_type, exercise_id, max_score, working_time FROM WORKING_TIME W1
               WHERE NOT EXISTS (SELECT 1 FROM FIRST_TIME_MAX_SCORE F WHERE F.contributor_id = W1.contributor_id AND F.contributor_type = W1.contributor_type AND F.exercise_id = W1.exercise_id))),

              FILTERED_TIMES_UNTIL_MAX AS
              (
              SELECT contributor_id, contributor_type, exercise_id, max_score, CASE WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0' ELSE working_time END AS working_time_new
              FROM ALL_WORKING_TIMES_UNTIL_MAX
              )
                  SELECT contributor_id, contributor_type, exercise_id, MAX(max_score) AS max_score, sum(working_time_new) AS working_time
                  FROM FILTERED_TIMES_UNTIL_MAX
                  GROUP BY contributor_id, contributor_type, exercise_id
          ")
      parse_duration(result.first['working_time']).to_f
    rescue StandardError
      0
    end
  end

  def duplicate(attributes = {})
    exercise = dup
    exercise.attributes = attributes
    exercise_tags.each  {|et| exercise.exercise_tags << et.dup }
    files.each {|file| exercise.files << file.dup }
    exercise
  end

  def generate_token
    self.token ||= SecureRandom.hex(4)
  end
  private :generate_token

  def maximum_score(contributor = nil)
    if contributor
      submissions
        .where(contributor:, cause: %w[submit assess remoteSubmit remoteAssess])
        .where.not(score: nil)
        .order(score: :desc)
        .first&.score || 0
    else
      @maximum_score ||= if files.loaded?
                           files.filter(&:teacher_defined_assessment?).pluck(:weight).sum
                         else
                           files.teacher_defined_assessments.sum(:weight)
                         end
    end
  end

  def final_submission(contributor)
    submissions.final.order(created_at: :desc).find_by(contributor:)
  end

  def solved_by?(contributor)
    maximum_score(contributor).to_i == maximum_score.to_i
  end

  def finishers_count(base = submissions)
    Submission.from(base.where(score: maximum_score, cause: %w[submit assess remoteSubmit remoteAssess]).group(:contributor_id, :contributor_type).select(:contributor_id, :contributor_type), 'submissions').count
  end

  def set_default_values
    set_default_values_if_present(public: false)
  end
  private :set_default_values

  def valid_main_file?
    if files.many?(&:main_file?)
      errors.add(:files, :at_most_one_main_file)
    end
  end
  private :valid_main_file?

  def valid_submission_deadlines?
    return true unless submission_deadline.present? || late_submission_deadline.present?

    valid = true
    if late_submission_deadline.present? && submission_deadline.blank?
      errors.add(:late_submission_deadline, :not_alone)
      valid = false
    end

    if submission_deadline.present? && late_submission_deadline.present? &&
       late_submission_deadline < submission_deadline
      errors.add(:late_submission_deadline, :not_before_submission_deadline)
      valid = false
    end

    valid
  end
  private :valid_submission_deadlines?

  def needs_more_feedback?
    user_exercise_feedbacks.size <= MAX_GROUP_EXERCISE_FEEDBACKS
  end

  def last_submission_per_contributor
    Submission.joins("JOIN (
          SELECT
              contributor_id,
              contributor_type,
              first_value(id) OVER (PARTITION BY contributor_id, contributor_type ORDER BY created_at DESC) AS fv
          FROM submissions
          WHERE #{Submission.sanitize_sql(['exercise_id = ?', id])}
        ) AS t ON t.fv = submissions.id").distinct
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title id internal_title]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[execution_environment]
  end
end
