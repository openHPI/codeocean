require File.expand_path('../../../lib/active_model/validations/boolean_presence_validator', __FILE__)

class Exercise < ActiveRecord::Base
  include Context
  include Creation
  include DefaultValues

  after_initialize :generate_token
  after_initialize :set_default_values

  belongs_to :execution_environment
  has_many :submissions
  belongs_to :team

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


  def average_percentage
    (average_score / maximum_score * 100).round if average_score
  end

  def average_score
    if submissions.exists?(cause: 'submit')
      maximum_scores_query = submissions.select('MAX(score) AS maximum_score').where(cause: 'submit').group(:user_id).to_sql.sub('$1', id.to_s)
      self.class.connection.execute("SELECT AVG(maximum_score) AS average_score FROM (#{maximum_scores_query}) AS maximum_scores").first['average_score'].to_f
    else 0 end
  end

  def average_number_of_submissions
    user_count = internal_users.distinct.count + external_users.distinct.count
    return user_count == 0 ? 0 : submissions.count() / user_count.to_f()
  end

  def user_working_time_query
    """
      SELECT user_id,
             sum(working_time_new) AS working_time
      FROM
        (SELECT user_id,
                CASE WHEN working_time >= '0:30:00' THEN '0' ELSE working_time END AS working_time_new
         FROM
            (SELECT user_id,
                    id,
                    (created_at - lag(created_at) over (PARTITION BY user_id
                                                        ORDER BY id)) AS working_time
            FROM submissions
            WHERE exercise_id=#{id}) AS foo) AS bar
      GROUP BY user_id
    """
  end

  def average_working_time
    self.class.connection.execute("""
      SELECT avg(working_time) as average_time
      FROM
        (#{user_working_time_query}) AS baz;
    """).first['average_time']
  end

  def average_working_time_for(user_id)
    self.class.connection.execute("""
      #{user_working_time_query}
      HAVING user_id = #{user_id}
    """).first['working_time']
  end

  def duplicate(attributes = {})
    exercise = dup
    exercise.attributes = attributes
    files.each { |file| exercise.files << file.dup }
    exercise
  end

  def generate_token
    self.token ||= SecureRandom.hex(4)
  end
  private :generate_token

  def maximum_score
    files.teacher_defined_tests.sum(:weight)
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
end
