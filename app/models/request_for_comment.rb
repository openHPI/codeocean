class RequestForComment < ActiveRecord::Base
  include Creation
  belongs_to :submission
  belongs_to :exercise
  belongs_to :file, class_name: 'CodeOcean::File'

  has_many :comments, through: :submission
  has_many :subscriptions

  scope :unsolved, -> { where(solved: [false, nil]) }

    def self.last_per_user(n = 5)
      from("(#{row_number_user_sql}) as request_for_comments")
          .where("row_number <= ?", n)
          .group('request_for_comments.id, request_for_comments.user_id, request_for_comments.exercise_id,
                  request_for_comments.file_id, request_for_comments.question, request_for_comments.created_at,
          request_for_comments.updated_at, request_for_comments.user_type, request_for_comments.solved,
          request_for_comments.full_score_reached, request_for_comments.submission_id, request_for_comments.row_number')
          # ugly, but necessary
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

  def commenters
    commenters = []
    comments.distinct.to_a.each {|comment|
      commenters.append comment.user
    }
    commenters.uniq {|user| user.id}
  end

  def self.with_last_activity
    self.joins('join "submissions" s on s.id = request_for_comments.submission_id
                left outer join "files" f on f.context_id = s.id
                left outer join "comments" c on c.file_id = f.id')
        .group('request_for_comments.id')
        .select('request_for_comments.*, max(c.updated_at) as last_comment')
  end

  def to_s
    "RFC-" + self.id.to_s
  end

    private
    def self.row_number_user_sql
      select("id, user_id, exercise_id, file_id, question, created_at, updated_at, user_type, solved, full_score_reached, submission_id, row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC) as row_number").to_sql
    end
end
