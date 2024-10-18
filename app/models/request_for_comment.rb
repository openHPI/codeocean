# frozen_string_literal: true

class RequestForComment < ApplicationRecord
  include Creation
  include ActionCableHelper

  # SOLVED:      The author explicitly marked the RfC as solved.
  # SOFT_SOLVED: The author did not mark the RfC as solved but reached the maximum score in the corresponding exercise at any time.
  # ONGOING:     The author did not mark the RfC as solved and did not reach the maximum score in the corresponding exercise yet.
  # ALL:         Any RfC, regardless of the author marking it as solved or reaching the maximum score in the corresponding exercise.
  STATE = [SOLVED = :solved, SOFT_SOLVED = :soft_solved, ONGOING = :unsolved, ALL = :all].freeze

  belongs_to :submission
  belongs_to :exercise
  belongs_to :file, class_name: 'CodeOcean::File'

  has_many :comments, through: :submission
  has_many :subscriptions, dependent: :destroy

  scope :unsolved, -> { where(solved: [false, nil]) }
  scope :in_range, ->(from, to) { from == DateTime.new(0) && to > 5.seconds.ago ? all : where(created_at: from..to) }
  scope :with_comments, -> { select {|rfc| rfc.comments.any? } }

  # after_save :trigger_rfc_action_cable

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

  def self.parent_resource
    Exercise
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
    def state(filter = RequestForComment::ALL)
      # This method is used as a scope filter for Ransack

      case filter.to_sym
        when RequestForComment::SOLVED
          where(solved: true)
        when RequestForComment::SOFT_SOLVED
          unsolved.where(full_score_reached: true)
        when RequestForComment::ONGOING
          unsolved.where(full_score_reached: false)
        else # 'all'
          all
      end
    end

    def ransackable_associations(_auth_object = nil)
      %w[exercise submission]
    end

    def ransackable_scopes(_auth_object = nil)
      %w[state]
    end

    def ransortable_attributes(_auth_object = nil)
      %w[created_at]
    end

    # @param [Arel::Nodes::TableAlias] from_arel_table The Arel table to select from.
    # @param [Integer] count The number of RfCs to select per user. `nil` selects all.
    # @return [Arel::Nodes::TableAlias] The resulting Arel query limited to `count` RfCs per user.
    def with_last_per_user_arel(from_arel_table, count = 5)
      # If no limit should be applied, we don't need to perform any calculations.
      return from_arel_table if count.nil?

      row_number_column_name = :row_number
      # We fist need to assign a row number to each RfC per user.
      search_result_with_row_number_arel = RequestForComment.with_row_number_arel(from_arel_table, row_number_column_name)
      # Then we can select the first `count` RfCs per user.
      RequestForComment.with_first_n_row_numbers_arel(search_result_with_row_number_arel, row_number_column_name, count)
    end

    # @param [RanSack::Search] search The Ransack search object with the search parameters.
    # @return [Arel::Nodes::TableAlias] The resulting Arel query limited to the search parameters.
    def with_ransack_search_arel(search)
      rfc_table = RequestForComment.arel_table
      # We need to use `reorder(nil)` to remove any existing order from the search.
      # This is required to ensure the correct filtering and pagination is performed.
      search.result.reorder(nil).arel.as(rfc_table.name)
    end

    # @param [RanSack::Search] sort The Ransack search object with the sort parameters. Any search parameters are ignored.
    # @param [Array<Arel::Nodes::Ordering>] secondary_sort_options Additional sort options to apply after the Ransack sort.
    # @param [Arel::Nodes::TableAlias] from_arel_table The Arel table to select from.
    # @return [Arel::Nodes::TableAlias] The resulting Arel query sorted by the sort parameters.
    def with_ransack_sort_arel(sort, secondary_sort_options, from_arel_table)
      rfc_table = RequestForComment.arel_table
      sorted_arel = sort.result.arel

      if secondary_sort_options.present?
        sorted_arel = sorted_arel.order(*secondary_sort_options)
      end

      sorted_arel.from(from_arel_table).as(rfc_table.name)
    end

    # @param [Arel::Nodes::TableAlias] from_arel_table The Arel table to select from.
    # @param [String] row_number_column_name The name of the column to store the row number in.
    # @return [Arel::Nodes::TableAlias] The resulting Arel query annotated with the row number.
    def with_row_number_arel(from_arel_table, row_number_column_name)
      rfc_table = RequestForComment.arel_table

      row_number = Arel::Nodes::Window.new
        .partition(rfc_table[:user_id], rfc_table[:user_type])
        # Since we want to show the n newest RfCs per user, we need to order by `created_at` in descending order.
        # This is not related to the order of the RfCs in the result set (e.g., the Ransack ordering).
        .order(rfc_table[:created_at].desc)

      row_number_function = Arel::Nodes::NamedFunction.new('row_number', [])
        .over(row_number)
        .as(row_number_column_name.to_s)

      rfc_table.project(rfc_table[Arel.star], row_number_function)
        .from(from_arel_table).as(rfc_table.name)
    end

    # @param [Arel::Nodes::TableAlias] from_arel_table The Arel table to select from.
    # @param [String] row_number_column_name The name of the column to store the row number in.
    # @param [Integer] max_row_number The maximum row number to select.
    # @return [Arel::Nodes::TableAlias] The resulting Arel query limited to the first `max_row_number` RfCs.
    def with_first_n_row_numbers_arel(from_arel_table, row_number_column_name, max_row_number)
      rfc_table = RequestForComment.arel_table
      column_names = RequestForComment.column_names.map {|name| rfc_table[name.to_sym] }

      rfc_table.project(*column_names)
        .where(rfc_table[row_number_column_name].lteq(max_row_number))
        .group(rfc_table[row_number_column_name], *column_names)
        .from(from_arel_table).as(rfc_table.name)
    end

    # @param [Arel::Nodes::TableAlias] from_arel_table The Arel table to select from.
    # @return [Arel::Nodes::TableAlias] The resulting Arel query annotated with the last activity timestamp of the RfC.
    def with_last_activity_arel(from_arel_table)
      rfc_table = RequestForComment.arel_table
      submissions_table = Submission.arel_table
      files_table = CodeOcean::File.arel_table
      comments_table = Comment.arel_table
      column_names = RequestForComment.column_names.map {|name| rfc_table[name.to_sym] }

      # If no comment is available yet, we want to show the last activity of the RfC.
      # This behavior is inline with `views/request_for_comments/index.html.slim`.
      last_activity = Arel::Nodes::NamedFunction.new('COALESCE', [comments_table[:updated_at].maximum, rfc_table[:updated_at]])

      # We need to join the submissions, files, and comments tables to get the last activity timestamp of a comment.
      # This query is rather expensive and should be performed as late as possible.
      rfc_table
        .project(*column_names, last_activity.as('last_activity'))
        .join(submissions_table)
        .on(submissions_table[:id].eq(rfc_table[:submission_id]))
        .join(files_table, Arel::Nodes::OuterJoin)
        .on(files_table[:context_id].eq(submissions_table[:id]))
        .join(comments_table, Arel::Nodes::OuterJoin)
        .on(comments_table[:file_id].eq(files_table[:id]))
        .group(*column_names)
        .from(from_arel_table).as(rfc_table.name)
    end

    # @param [Array<Integer>, Array<ActiveRecord::Relation<RequestForComment>>] rfc_ids The IDs of the RfCs to select.
    # @return [Arel::Nodes::TableAlias] The resulting Arel query limited to the specified RfCs.
    def with_id_arel(rfc_ids)
      rfc_table = RequestForComment.arel_table

      RequestForComment.where(id: rfc_ids).arel.as(rfc_table.name)
    end
  end
end
