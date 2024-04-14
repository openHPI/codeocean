# frozen_string_literal: true

require 'nokogiri'

class Exercise < ApplicationRecord
  include Context
  include Creation
  include DefaultValues
  include TimeHelper

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

  scope :with_submissions, -> { where('id IN (SELECT exercise_id FROM submissions)') }
  scope :with_programming_groups, -> { where('id IN (SELECT exercise_id FROM programming_groups)') }

  validate :valid_main_file?
  validate :valid_submission_deadlines?
  validates :description, presence: true
  validates :execution_environment, presence: true, if: -> { !unpublished? }
  validates :public, inclusion: [true, false]
  validates :unpublished, inclusion: [true, false]
  validates :title, presence: true
  validates :token, presence: true, uniqueness: true
  validates :uuid, uniqueness: {if: -> { uuid.present? }}

  @working_time_statistics = nil
  attr_reader :working_time_statistics

  MAX_GROUP_EXERCISE_FEEDBACKS = 20

  def average_percentage
    if average_score && (maximum_score.to_d != BigDecimal('0.0')) && submissions.exists?(cause: 'submit')
      (average_score / maximum_score * 100).round(2)
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

  def average_score
    Submission.from(
      submissions.group(:contributor_id, :contributor_type)
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
      .where(contributor:, cause: %w[submit assess])
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
    WITH working_time_between_submissions AS (
      SELECT submissions.contributor_id,
         submissions.contributor_type,
         score,
         created_at,
         (created_at - lag(created_at) over (PARTITION BY submissions.contributor_type, submissions.contributor_id, exercise_id
           ORDER BY created_at)) AS working_time
      FROM submissions
      WHERE #{self.class.sanitize_sql(['exercise_id = ? and study_group_id = ?', exercise_id, study_group_id])} #{self.class.sanitize_sql(additional_filter)}),
    working_time_with_deltas_ignored AS (
      SELECT contributor_id,
             contributor_type,
             score,
             sum(CASE WHEN score IS NOT NULL THEN 1 ELSE 0 END)
                 over (ORDER BY contributor_type, contributor_id, created_at ASC)                 AS change_in_score,
             created_at,
             CASE WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0' ELSE working_time END AS working_time_filtered
      FROM working_time_between_submissions
    ),
    working_times_with_score_expanded AS (
      SELECT contributor_id,
             contributor_type,
             created_at,
             working_time_filtered,
             first_value(score)
                         over (PARTITION BY contributor_type, contributor_id, change_in_score ORDER BY created_at ASC) AS corrected_score
      FROM working_time_with_deltas_ignored
    ),
    working_times_with_duplicated_last_row_per_score AS (
      SELECT *
      FROM working_times_with_score_expanded
      UNION ALL
      -- Duplicate last row per user and score and make it unique by setting another created_at timestamp.
      -- In addition, the working time is set to zero in order to prevent getting a wrong time.
      -- This duplication is needed, as we will shift the scores and working times by one and need to ensure not to loose any information.
      SELECT DISTINCT ON (contributor_type, contributor_id, corrected_score) contributor_id,
                                                               contributor_type,
                                                               created_at + INTERVAL '1us',
                                                               '00:00:00' as working_time_filtered,
                                                               corrected_score
      FROM working_times_with_score_expanded
    ),
    working_times_with_score_not_null_and_shifted AS (
      SELECT contributor_id,
             contributor_type,
             coalesce(lag(corrected_score) over (PARTITION BY contributor_type, contributor_id ORDER BY created_at ASC),
                      0) AS shifted_score,
             created_at,
             working_time_filtered
      FROM working_times_with_duplicated_last_row_per_score
    ),
    working_times_to_be_sorted AS (
      SELECT contributor_id,
             contributor_type,
             shifted_score                                                          AS score,
             MIN(created_at)                                                        AS start_time,
             SUM(working_time_filtered)                                             AS working_time_per_score,
             SUM(SUM(working_time_filtered)) over (PARTITION BY contributor_type, contributor_id) AS total_working_time
      FROM working_times_with_score_not_null_and_shifted
      GROUP BY contributor_id, contributor_type, score
    ),
    working_times_with_index AS (
      SELECT (dense_rank() over (ORDER BY total_working_time, contributor_type, contributor_id ASC) - 1) AS index,
             contributor_id,
             contributor_type,
             score,
             start_time,
             working_time_per_score,
             total_working_time
      FROM working_times_to_be_sorted)
    SELECT index,
       contributor_id,
       contributor_type,
       name,
       score,
       start_time,
       working_time_per_score,
       total_working_time
    FROM working_times_with_index
       JOIN external_users ON contributor_type = 'ExternalUser' AND contributor_id = external_users.id
    UNION ALL
    SELECT index,
       contributor_id,
       contributor_type,
       name,
       score,
       start_time,
       working_time_per_score,
       total_working_time
    FROM working_times_with_index
       JOIN internal_users ON contributor_type = 'InternalUser' AND contributor_id = internal_users.id
    UNION ALL
    SELECT index,
       contributor_id,
       contributor_type,
       concat('PG ', programming_groups.id::varchar) AS name,
       score,
       start_time,
       working_time_per_score,
       total_working_time
    FROM working_times_with_index
       JOIN programming_groups ON contributor_type = 'ProgrammingGroup' AND contributor_id = programming_groups.id
    ORDER BY index, score ASC;
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
                        id,
                        exercise_id,
                        Max(score)                                                                                  AS max_score,
                        (created_at - Lag(created_at) OVER (partition BY contributor_id, exercise_id ORDER BY created_at)) AS working_time
               FROM     submissions
               WHERE    #{self.class.sanitize_sql(['exercise_id = ?', id])}
               AND      contributor_type IN ('ExternalUser', 'ProgrammingGroup')
               GROUP BY contributor_id,
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
             SELECT id,
                    contributor_id,
                    exercise_id,
                    max_score,
                    working_time,
                    rn
             FROM   (
                             SELECT   id,
                                      contributor_id,
                                      exercise_id,
                                      max_score,
                                      working_time,
                                      Row_number() OVER(partition BY contributor_id, exercise_id ORDER BY id ASC) AS rn
                             FROM     time_max_score) T
             WHERE  rn = 1), times_until_max_points AS
      (
             SELECT w.id,
                    w.contributor_id,
                    w.exercise_id,
                    w.max_score,
                    w.working_time,
                    m.id AS reachedmax_at
             FROM   working_time W,
                    first_time_max_score M
             WHERE  w.contributor_id = m.contributor_id
             AND    w.exercise_id = m.exercise_id
             AND    w.id <= m.id),
      -- if user never makes it to max points, take all times
      all_working_times_until_max AS (
      (
             SELECT id,
                    contributor_id,
                    exercise_id,
                    max_score,
                    working_time
             FROM   times_until_max_points)
      UNION ALL
                (
                       SELECT id,
                              contributor_id,
                              exercise_id,
                              max_score,
                              working_time
                       FROM   working_time W1
                       WHERE  NOT EXISTS
                              (
                                     SELECT 1
                                     FROM   first_time_max_score F
                                     WHERE  f.contributor_id = w1.contributor_id
                                     AND    f.exercise_id = w1.exercise_id))), filtered_times_until_max AS
      (
             SELECT contributor_id,
                    exercise_id,
                    max_score,
                    CASE
                           WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0'
                           ELSE working_time
                    END AS working_time_new
             FROM   all_working_times_until_max ), result AS
      (
               SELECT   e.external_id AS external_contributor_id,
                        f.contributor_id,
                        exercise_id,
                        Max(max_score)        AS max_score,
                        Sum(working_time_new) AS working_time
               FROM     filtered_times_until_max f,
                        external_users e
               WHERE    f.contributor_id = e.id
               GROUP BY e.external_id,
                        f.contributor_id,
                        exercise_id )
      SELECT   unnest(percentile_cont(#{self.class.sanitize_sql(['array[?]', quantiles])}) within GROUP (ORDER BY working_time))
      FROM     result
      ")
    if result.count.positive?
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
    contributor_type = contributor.class.name
    begin
      result = self.class.connection.exec_query("
              WITH WORKING_TIME AS
              (SELECT contributor_id,
                                 id,
                                 exercise_id,
                                 max(score) AS max_score,
                                 (created_at - lag(created_at) OVER (PARTITION BY contributor_id, exercise_id
                                                                     ORDER BY created_at)) AS working_time
                         FROM submissions
                         WHERE exercise_id = #{id} AND contributor_id = #{contributor.id} AND contributor_type = '#{contributor_type}'
                         GROUP BY contributor_id, id, exercise_id),
              MAX_POINTS AS
              (SELECT context_id AS ex_id, sum(weight) AS max_points FROM files WHERE context_type = 'Exercise' AND context_id = #{id} AND role IN ('teacher_defined_test', 'teacher_defined_linter') GROUP BY context_id),

              -- filter for rows containing max points
              TIME_MAX_SCORE AS
              (SELECT *
              FROM WORKING_TIME W1, MAX_POINTS MS
              WHERE W1.exercise_id = ex_id AND W1.max_score = MS.max_points),

              -- find row containing the first time max points
              FIRST_TIME_MAX_SCORE AS
              ( SELECT id,contributor_id,exercise_id,max_score,working_time, rn
                FROM (
                  SELECT id,contributor_id,exercise_id,max_score,working_time,
                      ROW_NUMBER() OVER(PARTITION BY contributor_id, exercise_id ORDER BY id ASC) AS rn
                  FROM TIME_MAX_SCORE) T
               WHERE rn = 1),

              TIMES_UNTIL_MAX_POINTS AS (
                  SELECT W.id, W.contributor_id, W.exercise_id, W.max_score, W.working_time, M.id AS reachedmax_at
                  FROM WORKING_TIME W, FIRST_TIME_MAX_SCORE M
                  WHERE W.contributor_id = M.contributor_id AND W.exercise_id = M.exercise_id AND W.id <= M.id),

              -- if contributor never makes it to max points, take all times
              ALL_WORKING_TIMES_UNTIL_MAX AS
              ((SELECT id, contributor_id, exercise_id, max_score, working_time FROM TIMES_UNTIL_MAX_POINTS)
              UNION ALL
              (SELECT id, contributor_id, exercise_id, max_score, working_time FROM WORKING_TIME W1
               WHERE NOT EXISTS (SELECT 1 FROM FIRST_TIME_MAX_SCORE F WHERE F.contributor_id = W1.contributor_id AND F.exercise_id = W1.exercise_id))),

              FILTERED_TIMES_UNTIL_MAX AS
              (
              SELECT contributor_id,exercise_id, max_score, CASE WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0' ELSE working_time END AS working_time_new
              FROM ALL_WORKING_TIMES_UNTIL_MAX
              )
                  SELECT e.external_id AS external_contributor_id, f.contributor_id, exercise_id, MAX(max_score) AS max_score, sum(working_time_new) AS working_time
                  FROM FILTERED_TIMES_UNTIL_MAX f, EXTERNAL_USERS e
                  WHERE f.contributor_id = e.id GROUP BY e.external_id, f.contributor_id, exercise_id
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

  def determine_file_role_from_proforma_file(task_node, file_node)
    file_id = file_node.xpath('@id')
    file_class = file_node.xpath('@class').first.value
    comment = file_node.xpath('@comment').first.value
    is_referenced_by_test = task_node.xpath("p:tests/p:test/p:filerefs/p:fileref[@id=#{file_id}]")
    is_referenced_by_model_solution = task_node.xpath("p:model-solutions/p:model-solution/p:filerefs/p:fileref[@id=#{file_id}]")
    if is_referenced_by_test && (file_class == 'internal')
      return 'teacher_defined_test'
    elsif is_referenced_by_model_solution && (file_class == 'internal')
      return 'reference_implementation'
    elsif (file_class == 'template') && (comment == 'main')
      return 'main_file'
    end

    'regular_file'
  end

  def from_proforma_xml(xml_string)
    # how to extract the proforma functionality into a different module in rails?
    xml = Nokogiri::XML(xml_string)
    xml.collect_namespaces
    task_node = xml.xpath('/root/p:task')
    description = task_node.xpath('p:description/text()')[0].content
    self.attributes = {
      title: task_node.xpath('p:meta-data/p:title/text()')[0].content,
      description:,
      instructions: description,
    }
    task_node.xpath('p:files/p:file').all? do |file|
      file_name_split = file.xpath('@filename').first.value.split('.')
      file_class = file.xpath('@class').first.value
      role = determine_file_role_from_proforma_file(task_node, file)
      feedback_message_nodes = task_node.xpath('p:tests/p:test/p:test-configuration/c:feedback-message/text()')
      files.build({
        name: file_name_split.first,
        content: file.xpath('text()').first.content,
        read_only: false,
        hidden: file_class == 'internal',
        role:,
        feedback_message: role == 'teacher_defined_test' ? feedback_message_nodes.first.content : nil,
        file_type: FileType.find_by(
          file_extension: ".#{file_name_split.second}"
        ),
      })
    end
    self.execution_environment_id = 1
  end

  def generate_token
    self.token ||= SecureRandom.hex(4)
  end
  private :generate_token

  def maximum_score(contributor = nil)
    if contributor
      submissions
        .where(contributor:, cause: %w[submit assess])
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

  def finishers_count
    Submission.from(submissions.where(score: maximum_score, cause: %w[submit assess remoteSubmit remoteAssess]).group(:contributor_id, :contributor_type).select(:contributor_id, :contributor_type), 'submissions').count
  end

  def set_default_values
    set_default_values_if_present(public: false)
  end
  private :set_default_values

  def to_s
    title
  end

  def valid_main_file?
    if files.count(&:main_file?) > 1
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
