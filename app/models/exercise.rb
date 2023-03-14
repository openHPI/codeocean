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
  has_many :exercise_tips
  has_many :tips, through: :exercise_tips

  has_many :external_users, source: :user, source_type: 'ExternalUser', through: :submissions
  has_many :internal_users, source: :user, source_type: 'InternalUser', through: :submissions
  alias users external_users

  scope :with_submissions, -> { where('id IN (SELECT exercise_id FROM submissions)') }

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
    if users.distinct.count.zero?
      0
    else
      (100.0 / users.distinct.count * finishers.count).round(2)
    end
  end

  def average_score
    if submissions.exists?(cause: 'submit')
      maximum_scores_query = submissions.select('MAX(score) AS maximum_score').group(:user_id).to_sql.sub('$1', id.to_s)
      self.class.connection.exec_query("SELECT AVG(maximum_score) AS average_score FROM (#{maximum_scores_query}) AS maximum_scores").first['average_score'].to_f
    else
      0
    end
  end

  def average_number_of_submissions
    user_count = internal_users.distinct.count + external_users.distinct.count
    user_count.zero? ? 0 : submissions.count / user_count.to_f
  end

  def time_maximum_score(user)
    submissions.where(user:).where("cause IN ('submit','assess')").where.not(score: nil).order('score DESC, created_at ASC').first.created_at
  rescue StandardError
    Time.zone.at(0)
  end

  def user_working_time_query
    "
      SELECT user_id,
             user_type,
             SUM(working_time_new) AS working_time,
             MAX(score) AS score
      FROM
        (SELECT user_id,
                user_type,
                score,
                CASE WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0' ELSE working_time END AS working_time_new
         FROM
            (SELECT user_id,
                    user_type,
                    score,
                    id,
                    (created_at - lag(created_at) over (PARTITION BY user_id, exercise_id
                                                        ORDER BY created_at)) AS working_time
            FROM submissions
            WHERE #{self.class.sanitize_sql(['exercise_id = ?', id])}) AS foo) AS bar
      GROUP BY user_id, user_type
    "
  end

  def study_group_working_time_query(exercise_id, study_group_id, additional_filter)
    "
    WITH working_time_between_submissions AS (
      SELECT submissions.user_id,
         submissions.user_type,
         score,
         created_at,
         (created_at - lag(created_at) over (PARTITION BY submissions.user_type, submissions.user_id, exercise_id
           ORDER BY created_at)) AS working_time
      FROM submissions
      WHERE #{self.class.sanitize_sql(['exercise_id = ? and study_group_id = ?', exercise_id, study_group_id])} #{self.class.sanitize_sql(additional_filter)}),
    working_time_with_deltas_ignored AS (
      SELECT user_id,
             user_type,
             score,
             sum(CASE WHEN score IS NOT NULL THEN 1 ELSE 0 END)
                 over (ORDER BY user_type, user_id, created_at ASC)                 AS change_in_score,
             created_at,
             CASE WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0' ELSE working_time END AS working_time_filtered
      FROM working_time_between_submissions
    ),
    working_times_with_score_expanded AS (
      SELECT user_id,
             user_type,
             created_at,
             working_time_filtered,
             first_value(score)
                         over (PARTITION BY user_type, user_id, change_in_score ORDER BY created_at ASC) AS corrected_score
      FROM working_time_with_deltas_ignored
    ),
    working_times_with_duplicated_last_row_per_score AS (
      SELECT *
      FROM working_times_with_score_expanded
      UNION ALL
      -- Duplicate last row per user and score and make it unique by setting another created_at timestamp.
      -- In addition, the working time is set to zero in order to prevent getting a wrong time.
      -- This duplication is needed, as we will shift the scores and working times by one and need to ensure not to loose any information.
      SELECT DISTINCT ON (user_type, user_id, corrected_score) user_id,
                                                               user_type,
                                                               created_at + INTERVAL '1us',
                                                               '00:00:00' as working_time_filtered,
                                                               corrected_score
      FROM working_times_with_score_expanded
    ),
    working_times_with_score_not_null_and_shifted AS (
      SELECT user_id,
             user_type,
             coalesce(lag(corrected_score) over (PARTITION BY user_type, user_id ORDER BY created_at ASC),
                      0) AS shifted_score,
             created_at,
             working_time_filtered
      FROM working_times_with_duplicated_last_row_per_score
    ),
    working_times_to_be_sorted AS (
      SELECT user_id,
             user_type,
             shifted_score                                                          AS score,
             MIN(created_at)                                                        AS start_time,
             SUM(working_time_filtered)                                             AS working_time_per_score,
             SUM(SUM(working_time_filtered)) over (PARTITION BY user_type, user_id) AS total_working_time
      FROM working_times_with_score_not_null_and_shifted
      GROUP BY user_id, user_type, score
    ),
    working_times_with_index AS (
      SELECT (dense_rank() over (ORDER BY total_working_time, user_type, user_id ASC) - 1) AS index,
             user_id,
             user_type,
             score,
             start_time,
             working_time_per_score,
             total_working_time
      FROM working_times_to_be_sorted)
    SELECT index,
       user_id,
       user_type,
       name,
       score,
       start_time,
       working_time_per_score,
       total_working_time
    FROM working_times_with_index
       JOIN external_users ON user_type = 'ExternalUser' AND user_id = external_users.id
    UNION ALL
    SELECT index,
       user_id,
       user_type,
       name,
       score,
       start_time,
       working_time_per_score,
       total_working_time
    FROM working_times_with_index
       JOIN internal_users ON user_type = 'InternalUser' AND user_id = internal_users.id
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
                          "AND user_id = #{user.id} AND user_type = '#{user.class.name}'"
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
        {id: tuple['user_id'], type: tuple['user_type'], name: ERB::Util.html_escape(tuple['name'])}
    end

    if results.ntuples.positive?
      first_index = results[0]['index']
      last_index = results[results.ntuples - 1]['index']
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
               SELECT   user_id,
                        id,
                        exercise_id,
                        Max(score)                                                                                  AS max_score,
                        (created_at - Lag(created_at) OVER (partition BY user_id, exercise_id ORDER BY created_at)) AS working_time
               FROM     submissions
               WHERE    #{self.class.sanitize_sql(['exercise_id = ?', id])}
               AND      user_type = 'ExternalUser'
               GROUP BY user_id,
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
                    user_id,
                    exercise_id,
                    max_score,
                    working_time,
                    rn
             FROM   (
                             SELECT   id,
                                      user_id,
                                      exercise_id,
                                      max_score,
                                      working_time,
                                      Row_number() OVER(partition BY user_id, exercise_id ORDER BY id ASC) AS rn
                             FROM     time_max_score) T
             WHERE  rn = 1), times_until_max_points AS
      (
             SELECT w.id,
                    w.user_id,
                    w.exercise_id,
                    w.max_score,
                    w.working_time,
                    m.id AS reachedmax_at
             FROM   working_time W,
                    first_time_max_score M
             WHERE  w.user_id = m.user_id
             AND    w.exercise_id = m.exercise_id
             AND    w.id <= m.id),
      -- if user never makes it to max points, take all times
      all_working_times_until_max AS (
      (
             SELECT id,
                    user_id,
                    exercise_id,
                    max_score,
                    working_time
             FROM   times_until_max_points)
      UNION ALL
                (
                       SELECT id,
                              user_id,
                              exercise_id,
                              max_score,
                              working_time
                       FROM   working_time W1
                       WHERE  NOT EXISTS
                              (
                                     SELECT 1
                                     FROM   first_time_max_score F
                                     WHERE  f.user_id = w1.user_id
                                     AND    f.exercise_id = w1.exercise_id))), filtered_times_until_max AS
      (
             SELECT user_id,
                    exercise_id,
                    max_score,
                    CASE
                           WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0'
                           ELSE working_time
                    END AS working_time_new
             FROM   all_working_times_until_max ), result AS
      (
               SELECT   e.external_id AS external_user_id,
                        f.user_id,
                        exercise_id,
                        Max(max_score)        AS max_score,
                        Sum(working_time_new) AS working_time
               FROM     filtered_times_until_max f,
                        external_users e
               WHERE    f.user_id = e.id
               GROUP BY e.external_id,
                        f.user_id,
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
    @working_time_statistics = {'InternalUser' => {}, 'ExternalUser' => {}}
    self.class.connection.exec_query(user_working_time_query).each do |tuple|
      tuple = tuple.merge('working_time' => format_time_difference(tuple['working_time']))
      @working_time_statistics[tuple['user_type']][tuple['user_id'].to_i] = tuple
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

  def accumulated_working_time_for_only(user)
    user_type = user.external_user? ? 'ExternalUser' : 'InternalUser'
    begin
      result = self.class.connection.exec_query("
              WITH WORKING_TIME AS
              (SELECT user_id,
                                 id,
                                 exercise_id,
                                 max(score) AS max_score,
                                 (created_at - lag(created_at) OVER (PARTITION BY user_id, exercise_id
                                                                     ORDER BY created_at)) AS working_time
                         FROM submissions
                         WHERE exercise_id = #{id} AND user_id = #{user.id} AND user_type = '#{user_type}'
                         GROUP BY user_id, id, exercise_id),
              MAX_POINTS AS
              (SELECT context_id AS ex_id, sum(weight) AS max_points FROM files WHERE context_type = 'Exercise' AND context_id = #{id} AND role IN ('teacher_defined_test', 'teacher_defined_linter') GROUP BY context_id),

              -- filter for rows containing max points
              TIME_MAX_SCORE AS
              (SELECT *
              FROM WORKING_TIME W1, MAX_POINTS MS
              WHERE W1.exercise_id = ex_id AND W1.max_score = MS.max_points),

              -- find row containing the first time max points
              FIRST_TIME_MAX_SCORE AS
              ( SELECT id,USER_id,exercise_id,max_score,working_time, rn
                FROM (
                  SELECT id,USER_id,exercise_id,max_score,working_time,
                      ROW_NUMBER() OVER(PARTITION BY user_id, exercise_id ORDER BY id ASC) AS rn
                  FROM TIME_MAX_SCORE) T
               WHERE rn = 1),

              TIMES_UNTIL_MAX_POINTS AS (
                  SELECT W.id, W.user_id, W.exercise_id, W.max_score, W.working_time, M.id AS reachedmax_at
                  FROM WORKING_TIME W, FIRST_TIME_MAX_SCORE M
                  WHERE W.user_id = M.user_id AND W.exercise_id = M.exercise_id AND W.id <= M.id),

              -- if user never makes it to max points, take all times
              ALL_WORKING_TIMES_UNTIL_MAX AS
              ((SELECT id, user_id, exercise_id, max_score, working_time FROM TIMES_UNTIL_MAX_POINTS)
              UNION ALL
              (SELECT id, user_id, exercise_id, max_score, working_time FROM WORKING_TIME W1
               WHERE NOT EXISTS (SELECT 1 FROM FIRST_TIME_MAX_SCORE F WHERE F.user_id = W1.user_id AND F.exercise_id = W1.exercise_id))),

              FILTERED_TIMES_UNTIL_MAX AS
              (
              SELECT user_id,exercise_id, max_score, CASE WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0' ELSE working_time END AS working_time_new
              FROM ALL_WORKING_TIMES_UNTIL_MAX
              )
                  SELECT e.external_id AS external_user_id, f.user_id, exercise_id, MAX(max_score) AS max_score, sum(working_time_new) AS working_time
                  FROM FILTERED_TIMES_UNTIL_MAX f, EXTERNAL_USERS e
                  WHERE f.user_id = e.id GROUP BY e.external_id, f.user_id, exercise_id
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

  def maximum_score(user = nil)
    if user
      # FIXME: where(user: user) will not work here!
      begin
        submissions.where(user:).where("cause IN ('submit','assess')").where.not(score: nil).order('score DESC').first.score || 0
      rescue StandardError
        0
      end
    else
      @maximum_score ||= if files.loaded?
                           files.filter(&:teacher_defined_assessment?).pluck(:weight).sum
                         else
                           files.teacher_defined_assessments.sum(:weight)
                         end
    end
  end

  def final_submission(user)
    submissions.final.where(user_id: user.id, user_type: user.class.name).order(created_at: :desc).first
  end

  def solved_by?(user)
    maximum_score(user).to_i == maximum_score.to_i
  end

  def finishers
    ExternalUser.joins(:submissions).where(submissions: {exercise_id: id, score: maximum_score,
cause: %w[submit assess remoteSubmit remoteAssess]}).distinct
  end

  def set_default_values
    set_default_values_if_present(public: false)
  end
  private :set_default_values

  def to_s
    title
  end

  def valid_main_file?
    if files.main_files.count > 1
      errors.add(:files,
        I18n.t('activerecord.errors.models.exercise.at_most_one_main_file'))
    end
  end
  private :valid_main_file?

  def valid_submission_deadlines?
    return unless submission_deadline.present? || late_submission_deadline.present?

    if late_submission_deadline.present? && submission_deadline.blank?
      errors.add(:late_submission_deadline,
        I18n.t('activerecord.errors.models.exercise.late_submission_deadline_not_alone'))
    end

    if submission_deadline.present? && late_submission_deadline.present? &&
       late_submission_deadline < submission_deadline
      errors.add(:late_submission_deadline,
        I18n.t('activerecord.errors.models.exercise.late_submission_deadline_not_before_submission_deadline'))
    end
  end
  private :valid_submission_deadlines?

  def needs_more_feedback?(submission)
    if submission.normalized_score.to_d == BigDecimal('1.0')
      user_exercise_feedbacks.final.size <= MAX_GROUP_EXERCISE_FEEDBACKS
    else
      user_exercise_feedbacks.intermediate.size <= MAX_GROUP_EXERCISE_FEEDBACKS
    end
  end

  def last_submission_per_user
    Submission.joins("JOIN (
          SELECT
              user_id,
              user_type,
              first_value(id) OVER (PARTITION BY user_id ORDER BY created_at DESC) AS fv
          FROM submissions
          WHERE exercise_id = #{id}
        ) AS t ON t.fv = submissions.id").distinct
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[execution_environment]
  end
end
