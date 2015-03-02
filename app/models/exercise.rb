class Exercise < ActiveRecord::Base
  include Context
  include Creation

  after_initialize :generate_token
  after_initialize :set_default_values

  belongs_to :execution_environment
  has_many :submissions
  belongs_to :team
  has_many :users, source_type: ExternalUser, through: :submissions

  scope :with_submissions, -> { where('id IN (SELECT exercise_id FROM submissions)') }

  validate :valid_main_file?
  validates :description, presence: true
  validates :execution_environment_id, presence: true
  validates :public, inclusion: {in: [true, false]}
  validates :title, presence: true
  validates :token, presence: true, uniqueness: true

  def average_percentage
    (average_score / maximum_score * 100).round if average_score
  end

  def average_score
    if submissions.exists?(cause: 'submit')
      maximum_scores_query = submissions.select('MAX(score) AS maximum_score').where(cause: 'submit').group(:user_id).to_sql.sub('$1', id.to_s)
      self.class.connection.execute("SELECT AVG(maximum_score) AS average_score FROM (#{maximum_scores_query}) AS maximum_scores").first['average_score'].to_f
    end
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
    files.where(role: 'teacher_defined_test').sum(:weight)
  end

  def set_default_values
    self.public ||= false
  end
  private :set_default_values

  def to_s
    title
  end

  def valid_main_file?
    if files.where(role: 'main_file').count > 1
      errors.add(:files, I18n.t('activerecord.errors.models.exercise.at_most_one_main_file'))
    end
  end
  private :valid_main_file?
end
