# frozen_string_literal: true

module StatisticsHelper
  WORKING_TIME_DELTA_IN_SECONDS = 5.minutes
  def self.working_time_larger_delta
    @working_time_larger_delta ||= ActiveRecord::Base.sanitize_sql(['working_time >= ?', '0:05:00'])
  end

  def statistics_data
    [
      {
        key: 'users',
          name: t('statistics.sections.users'),
          entries: user_statistics,
      },
      {
        key: 'exercises',
          name: t('statistics.sections.exercises'),
          entries: exercise_statistics,
      },
      {
        key: 'request_for_comments',
          name: t('statistics.sections.request_for_comments'),
          entries: rfc_statistics,
      },
    ]
  end

  def user_statistics
    [
      {
        key: 'internal_users',
          name: t('activerecord.models.internal_user.other'),
          data: InternalUser.count,
          url: internal_users_path,
      },
      {
        key: 'external_users',
          name: t('activerecord.models.external_user.other'),
          data: ExternalUser.count,
          url: external_users_path,
      },
      {
        key: 'currently_active',
          name: t('statistics.entries.users.currently_active'),
          data: Submission.where(created_at: 5.minutes.ago.., user_type: ExternalUser.name).distinct.count(:user_id),
          url: statistics_graphs_path,
      },
    ]
  end

  def exercise_statistics
    [
      {
        key: 'exercises',
          name: t('activerecord.models.exercise.other'),
          data: Exercise.count,
          url: exercises_path,
      },
      {
        key: 'average_submissions',
          name: t('statistics.entries.exercises.average_number_of_submissions'),
          data: (Submission.count.to_f / Exercise.count).round(2),
      },
      {
        key: 'submissions_per_minute',
          name: t('statistics.entries.exercises.submissions_per_minute'),
          data: (Submission.where('created_at >= ?', DateTime.now - 1.hour).count.to_f / 60).round(2),
          unit: '/min',
          url: statistics_graphs_path,
      },
      {
        key: 'autosaves_per_minute',
          name: t('statistics.entries.exercises.autosaves_per_minute'),
          data: (Submission.where('created_at >= ?',
            DateTime.now - 1.hour).where(cause: 'autosave').count.to_f / 60).round(2),
          unit: '/min',
      },
      {
        key: 'container_requests_per_minute',
          name: t('statistics.entries.exercises.container_requests_per_minute'),
          # This query is actually quite expensive since we do not have an index on the created_at column.
          data: (Testrun.where(created_at: DateTime.now - 1.hour..).count.to_f / 60).round(2),
          unit: '/min',
      },
      {
        key: 'execution_environments',
          name: t('activerecord.models.execution_environment.other'),
          data: ExecutionEnvironment.count,
          url: execution_environments_path,
      },
      {
        key: 'exercise_collections',
          name: t('activerecord.models.exercise_collection.other'),
          data: ExerciseCollection.count,
          url: exercise_collections_path,
      },
    ]
  end

  def rfc_statistics
    rfc_activity_data + [
      {
        key: 'comments',
          name: t('activerecord.models.comment.other'),
          data: Comment.count,
      },
    ]
  end

  def user_activity_live_data
    [
      {
        key: 'active_in_last_hour',
          name: t('statistics.entries.users.currently_active'),
          data: ExternalUser.joins(:submissions)
            .where(['submissions.created_at >= ?', DateTime.now - 5.minutes])
            .distinct('external_users.id').count,
      },
      {
        key: 'submissions_per_minute',
          name: t('statistics.entries.exercises.submissions_per_minute'),
          data: (Submission.where('created_at >= ?', DateTime.now - 1.hour).count.to_f / 60).round(2),
          unit: '/min',
          axis: 'right',
      },
    ]
  end

  def rfc_activity_data(from = DateTime.new(0), to = DateTime.now)
    [
      {
        key: 'rfcs',
          name: t('activerecord.models.request_for_comment.other'),
          data: RequestForComment.in_range(from, to).count,
          url: request_for_comments_path,
      },
      {
        key: 'percent_solved',
          name: t('statistics.entries.request_for_comments.percent_solved'),
          data: (100.0 / RequestForComment.in_range(from,
            to).count * RequestForComment.in_range(from, to).where(solved: true).count).round(1),
          unit: '%',
          axis: 'right',
          url: statistics_graphs_path,
      },
      {
        key: 'percent_soft_solved',
          name: t('statistics.entries.request_for_comments.percent_soft_solved'),
          data: (100.0 / RequestForComment.in_range(from,
            to).count * RequestForComment.in_range(from, to).unsolved.where(full_score_reached: true).count).round(1),
          unit: '%',
          axis: 'right',
          url: statistics_graphs_path,
      },
      {
        key: 'percent_unsolved',
          name: t('statistics.entries.request_for_comments.percent_unsolved'),
          data: (100.0 / RequestForComment.in_range(from,
            to).count * RequestForComment.in_range(from, to).unsolved.count).round(1),
          unit: '%',
          axis: 'right',
          url: statistics_graphs_path,
      },
      {
        key: 'rfcs_with_comments',
          name: t('statistics.entries.request_for_comments.with_comments'),
          data: RequestForComment.in_range(from,
            to).joins('join "submissions" s on s.id = request_for_comments.submission_id ' \
                      'join "files" f on f.context_id = s.id and f.context_type = \'Submission\' ' \
                      'join "comments" c on c.file_id = f.id').group('request_for_comments.id').count.size,
          url: statistics_graphs_path,
      },
    ]
  end

  def ranged_rfc_data(interval = 'year', from = DateTime.new(0), to = DateTime.now)
    [
      {
        key: 'rfcs',
          name: t('activerecord.models.request_for_comment.other'),
          data: RequestForComment.in_range(from, to)
            .select(RequestForComment.sanitize_sql(['date_trunc(?, created_at) AS "key", count(id) AS "value"', interval]))
            .group('key').order('key'),
      },
      {
        key: 'rfcs_solved',
          name: t('statistics.entries.request_for_comments.percent_solved'),
          data: RequestForComment.in_range(from, to)
            .where(solved: true)
            .select(RequestForComment.sanitize_sql(['date_trunc(?, created_at) AS "key", count(id) AS "value"', interval]))
            .group('key').order('key'),
      },
      {
        key: 'rfcs_soft_solved',
          name: t('statistics.entries.request_for_comments.percent_soft_solved'),
          data: RequestForComment.in_range(from, to).unsolved
            .where(full_score_reached: true)
            .select(RequestForComment.sanitize_sql(['date_trunc(?, created_at) AS "key", count(id) AS "value"', interval]))
            .group('key').order('key'),
      },
      {
        key: 'rfcs_unsolved',
          name: t('statistics.entries.request_for_comments.percent_unsolved'),
          data: RequestForComment.in_range(from, to).unsolved
            .select(RequestForComment.sanitize_sql(['date_trunc(?, created_at) AS "key", count(id) AS "value"', interval]))
            .group('key').order('key'),
      },
    ]
  end

  def ranged_user_data(interval = 'year', from = DateTime.new(0), to = DateTime.now)
    [
      {
        key: 'active',
          name: t('statistics.entries.users.active'),
          data: ExternalUser.joins(:submissions)
            .where(submissions: {created_at: from..to})
            .select(ExternalUser.sanitize_sql(['date_trunc(?, submissions.created_at) AS "key", count(distinct external_users.id) AS "value"', interval]))
            .group('key').order('key'),
      },
      {
        key: 'submissions',
          name: t('statistics.entries.exercises.submissions'),
          data: Submission.where(created_at: from..to)
            .select(Submission.sanitize_sql(['date_trunc(?, created_at) AS "key", count(id) AS "value"', interval]))
            .group('key').order('key'),
          axis: 'right',
      },
    ]
  end
end
