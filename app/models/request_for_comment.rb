class RequestForComment < ActiveRecord::Base
  belongs_to :exercise
  belongs_to :file, class_name: 'CodeOcean::File'
  belongs_to :user, polymorphic: true

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

  def last_submission
    Submission.find_by_sql(" select * from submissions
            where exercise_id = #{exercise_id} AND
            user_id =  #{user_id}
            order by created_at desc
            limit 1").first
  end

    private
    def self.row_number_user_sql
      select("id, user_id, exercise_id, file_id, requested_at, created_at, updated_at, user_type, row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC) as row_number").to_sql
    end
end
