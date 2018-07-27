require 'nokogiri'
require File.expand_path('../../../lib/active_model/validations/boolean_presence_validator', __FILE__)

class Exercise < ActiveRecord::Base
  include Context
  include Creation
  include DefaultValues

  after_initialize :generate_token
  after_initialize :set_default_values

  belongs_to :execution_environment
  has_many :submissions

  has_and_belongs_to_many :proxy_exercises
  has_many :user_proxy_exercise_exercises
  has_many :exercise_collection_items
  has_many :exercise_collections, through: :exercise_collection_items
  has_many :user_exercise_interventions
  has_many :interventions, through: :user_exercise_interventions
  has_many :exercise_tags
  has_many :tags, through: :exercise_tags
  accepts_nested_attributes_for :exercise_tags
  has_many :user_exercise_feedbacks

  has_many :external_users, source: :user, source_type: ExternalUser, through: :submissions
  has_many :internal_users, source: :user, source_type: InternalUser, through: :submissions
  alias_method :users, :external_users

  scope :with_submissions, -> { where('id IN (SELECT exercise_id FROM submissions)') }

  validate :valid_main_file?
  validates :description, presence: true
  validates :execution_environment_id, presence: true
  validates :public, boolean_presence: true
  validates :title, presence: true
  validates :token, presence: true, uniqueness: true

  @working_time_statistics = nil
  attr_reader :working_time_statistics

  MAX_EXERCISE_FEEDBACKS = 20


  def average_percentage
    if average_score and maximum_score != 0.0 and submissions.exists?(cause: 'submit')
      (average_score / maximum_score * 100).round
    else
      0
    end
  end

  def average_score
    if submissions.exists?(cause: 'submit')
      maximum_scores_query = submissions.select('MAX(score) AS maximum_score').group(:user_id).to_sql.sub('$1', id.to_s)
      self.class.connection.execute("SELECT AVG(maximum_score) AS average_score FROM (#{maximum_scores_query}) AS maximum_scores").first['average_score'].to_f
    else 0 end
  end

  def average_number_of_submissions
    user_count = internal_users.distinct.count + external_users.distinct.count
    return user_count == 0 ? 0 : submissions.count() / user_count.to_f()
  end

  def time_maximum_score(user)
    submissions.where(user: user).where("cause IN ('submit','assess')").where("score IS NOT NULL").order("score DESC, created_at ASC").first.created_at rescue Time.zone.at(0)
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
                CASE WHEN working_time >= '0:05:00' THEN '0' ELSE working_time END AS working_time_new
         FROM
            (SELECT user_id,
                    user_type,
                    score,
                    id,
                    (created_at - lag(created_at) over (PARTITION BY user_id, exercise_id
                                                        ORDER BY created_at)) AS working_time
            FROM submissions
            WHERE exercise_id=#{id}) AS foo) AS bar
      GROUP BY user_id, user_type
    "
  end

  def get_quantiles(quantiles)
    quantiles_str = "[" + quantiles.join(",") + "]"
    result = self.class.connection.execute("""
            WITH working_time AS
      (
               SELECT   user_id,
                        id,
                        exercise_id,
                        Max(score)                                                                                  AS max_score,
                        (created_at - Lag(created_at) OVER (partition BY user_id, exercise_id ORDER BY created_at)) AS working_time
               FROM     submissions
               WHERE    exercise_id = #{id}
               AND      user_type = 'ExternalUser'
               GROUP BY user_id,
                        id,
                        exercise_id), max_points AS
      (
               SELECT   context_id  AS ex_id,
                        Sum(weight) AS max_points
               FROM     files
               WHERE    context_type = 'Exercise'
               AND      context_id = #{id}
               AND      role = 'teacher_defined_test'
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
                           WHEN working_time >= '0:05:00' THEN '0'
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
      SELECT   unnest(percentile_cont(array#{quantiles_str}) within GROUP (ORDER BY working_time))
      FROM     result
    """)
    if result.count > 0
      quantiles.each_with_index.map{|q,i| Time.parse(result[i]["unnest"]).seconds_since_midnight}
    else
      quantiles.map{|q| 0}
    end

  end

  def retrieve_working_time_statistics
    @working_time_statistics = {}
    self.class.connection.execute(user_working_time_query).each do |tuple|
      @working_time_statistics[tuple['user_id'].to_i] = tuple
    end
  end

  def average_working_time
    self.class.connection.execute("""
      SELECT avg(working_time) as average_time
      FROM
        (#{user_working_time_query}) AS baz;
    """).first['average_time']
  end

  def average_working_time_for(user_id)
    if @working_time_statistics == nil
      retrieve_working_time_statistics()
    end
    @working_time_statistics[user_id]["working_time"]
  end

  def accumulated_working_time_for_only(user)
    user_type = user.external_user? ? "ExternalUser" : "InternalUser"
    Time.parse(self.class.connection.execute("""
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
        (SELECT context_id AS ex_id, sum(weight) AS max_points FROM files WHERE context_type = 'Exercise' AND context_id = #{id} AND role = 'teacher_defined_test' GROUP BY context_id),

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
        SELECT user_id,exercise_id, max_score, CASE WHEN working_time >= '0:05:00' THEN '0' ELSE working_time END AS working_time_new
        FROM ALL_WORKING_TIMES_UNTIL_MAX
        )
            SELECT e.external_id AS external_user_id, f.user_id, exercise_id, MAX(max_score) AS max_score, sum(working_time_new) AS working_time
            FROM FILTERED_TIMES_UNTIL_MAX f, EXTERNAL_USERS e
            WHERE f.user_id = e.id GROUP BY e.external_id, f.user_id, exercise_id
    """).first["working_time"]).seconds_since_midnight rescue 0
  end

  def duplicate(attributes = {})
    exercise = dup
    exercise.attributes = attributes
    exercise_tags.each  { |et| exercise.exercise_tags << et.dup }
    files.each { |file| exercise.files << file.dup }
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
    elsif (file_class == 'internal') && (comment == 'main')
    end
    return 'regular_file'
  end

  def from_proforma_xml(xml_string)
    # how to extract the proforma functionality into a different module in rails?
    xml = Nokogiri::XML(xml_string)
    xml.collect_namespaces
    task_node = xml.xpath('/root/p:task')
    description = task_node.xpath('p:description/text()')[0].content
    self.attributes = {
      title: task_node.xpath('p:meta-data/p:title/text()')[0].content,
      description: description,
      instructions: description
    }
    task_node.xpath('p:files/p:file').all? { |file|
      file_name_split = file.xpath('@filename').first.value.split('.')
      file_class = file.xpath('@class').first.value
      role = determine_file_role_from_proforma_file(task_node, file)
      feedback_message_nodes = task_node.xpath("p:tests/p:test/p:test-configuration/c:feedback-message/text()")
      files.build({
        name: file_name_split.first,
        content: file.xpath('text()').first.content,
        read_only: false,
        hidden: file_class == 'internal',
        role: role,
        feedback_message: (role == 'teacher_defined_test') ? feedback_message_nodes.first.content : nil,
        file_type: FileType.where(
          file_extension: ".#{file_name_split.second}"
        ).take
      })
    }
    self.execution_environment_id = 1
  end

  def generate_token
    self.token ||= SecureRandom.hex(4)
  end
  private :generate_token

  def maximum_score(user = nil)
    if user
      submissions.where(user: user).where("cause IN ('submit','assess')").where("score IS NOT NULL").order("score DESC").first.score || 0 rescue 0
    else
      files.teacher_defined_tests.sum(:weight)
    end
  end

  def has_user_solved(user)
    maximum_score(user).to_i == maximum_score.to_i
  end

  def finishers
    ExternalUser.joins(:submissions).where(submissions: {exercise_id: id, score: maximum_score, cause: %w(submit assess)}).distinct
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
      errors.add(:files, I18n.t('activerecord.errors.models.exercise.at_most_one_main_file'))
    end
  end
  private :valid_main_file?

  def needs_more_feedback?
    user_exercise_feedbacks.size <= MAX_EXERCISE_FEEDBACKS
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

end
