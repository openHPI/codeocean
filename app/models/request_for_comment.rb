class RequestForComment < ActiveRecord::Base
  include Creation
  belongs_to :exercise
  belongs_to :file, class_name: 'CodeOcean::File'

  before_create :set_requested_timestamp

    def self.last_per_user(n = 5)
      from("(#{row_number_user_sql}) as request_for_comments").where("row_number <= ?", n)
    end

    def set_requested_timestamp
        self.requested_at = Time.now
    end

  def submission
    Submission.find(file.context_id)
  end

  # not used right now, finds the last submission for the respective user and exercise.
  # might be helpful to check whether the exercise has been solved in the meantime.
  def last_submission
    Submission.find_by_sql(" select * from submissions
            where exercise_id = #{exercise_id} AND
            user_id =  #{user_id}
            order by created_at desc
            limit 1").first
  end

  # not used any longer, since we directly saved the submission_id now.
  # Was used before that to determine the submission belonging to the request_for_comment.
  def last_submission_before_creation
    Submission.find_by_sql(" select * from submissions
            where exercise_id = #{exercise_id} AND
            user_id =  #{user_id} AND
            '#{created_at.localtime}' > created_at
            order by created_at desc
            limit 1").first
  end

  def comments_count
    submission.files.map { |file| file.comments.size}.sum
  end

  def to_s
    "RFC-" + self.id.to_s
  end

    private
    def self.row_number_user_sql
      select("id, user_id, exercise_id, file_id, question, created_at, updated_at, user_type, solved, submission_id, row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC) as row_number").to_sql
    end
end
