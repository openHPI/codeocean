# frozen_string_literal: true

class RequestForComment < ApplicationRecord
  include Creation
  include ActionCableHelper

  # SOLVED:      The author explicitly marked the RfC as solved.
  # SOFT_SOLVED: The author did not mark the RfC as solved but reached the maximum score in the corresponding exercise at any time.
  # ONGOING:     The author did not mark the RfC as solved and did not reach the maximum score in the corresponding exercise yet.
  STATE = [SOLVED = :solved, SOFT_SOLVED = :soft_solved, ONGOING = :unsolved].freeze

  belongs_to :submission
  belongs_to :exercise
  belongs_to :file, class_name: 'CodeOcean::File'

  has_many :comments, through: :submission
  has_many :subscriptions, dependent: :destroy

  scope :unsolved, -> { where(solved: [false, nil]) }
  scope :in_range, ->(from, to) { from == DateTime.new(0) && to > 5.seconds.ago ? all : where(created_at: from..to) }
  scope :with_comments, -> { select {|rfc| rfc.comments.any? } }

  # after_save :trigger_rfc_action_cable

  def comments_count
    submission.files.sum {|file| file.comments.size }
  end

  def commenters
    comments.map(&:user).uniq
  end

  def comments?
    comments.any?
  end

  def to_s
    "RFC-#{id}"
  end

  def current_state
    state(solved, full_score_reached)
  end

  def old_state
    state(solved_before_last_save, full_score_reached_before_last_save)
  end

  private

  def state(solved, full_score_reached)
    if solved
      SOLVED
    elsif full_score_reached
      SOFT_SOLVED
    else
      ONGOING
    end
  end

  class << self
    def with_last_activity
      joins('join "submissions" s on s.id = request_for_comments.submission_id ' \
            'left outer join "files" f on f.context_id = s.id ' \
            'left outer join "comments" c on c.file_id = f.id')
        .group('request_for_comments.id')
        .select('request_for_comments.*, max(c.updated_at) as last_comment')
    end

    def last_per_user(count = 5)
      from(row_number_user_sql, :request_for_comments)
        .where('row_number <= ?', count)
        .group('request_for_comments.id, request_for_comments.user_id, request_for_comments.user_type, ' \
               'request_for_comments.exercise_id, request_for_comments.file_id, request_for_comments.question, ' \
               'request_for_comments.created_at, request_for_comments.updated_at, request_for_comments.solved, ' \
               'request_for_comments.full_score_reached, request_for_comments.submission_id, request_for_comments.row_number')
      # ugly, but necessary
    end

    def ransackable_associations(_auth_object = nil)
      %w[exercise submission]
    end

    def ransackable_attributes(_auth_object = nil)
      %w[solved]
    end

    private

    def row_number_user_sql
      select('
        request_for_comments.id,
        request_for_comments.user_id,
        request_for_comments.user_type,
        request_for_comments.exercise_id,
        request_for_comments.file_id,
        request_for_comments.question,
        request_for_comments.created_at,
        request_for_comments.updated_at,
        request_for_comments.solved,
        request_for_comments.full_score_reached,
        request_for_comments.submission_id,
        row_number() OVER (PARTITION BY request_for_comments.user_id, request_for_comments.user_type ORDER BY request_for_comments.created_at DESC) as row_number
      ')
    end
  end
end
