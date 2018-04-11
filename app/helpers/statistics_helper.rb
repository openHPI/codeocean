module StatisticsHelper

  def statistics_data
    [
        {
            key: 'users',
            name: t('statistics.sections.users'),
            entries: user_statistics
        },
        {
            key: 'exercises',
            name: t('statistics.sections.exercises'),
            entries: exercise_statistics
        },
        {
            key: 'request_for_comments',
            name: t('statistics.sections.request_for_comments'),
            entries: rfc_statistics
        }
    ]
  end

  def user_statistics
    [
        {
            key: 'internal_users',
            name: t('activerecord.models.internal_user.other'),
            data: InternalUser.count,
            url: internal_users_path
        },
        {
            key: 'external_users',
            name: t('activerecord.models.external_user.other'),
            data: ExternalUser.count,
            url: external_users_path
        },
        {
            key: 'currently_active',
            name: t('statistics.entries.users.currently_active'),
            data: ExternalUser.joins(:submissions)
                      .where(['submissions.created_at >= ?', DateTime.now - 5.minutes])
                      .distinct('external_users.id').count
        }
    ]
  end

  def exercise_statistics
    [
        {
            key: 'exercises',
            name: t('activerecord.models.exercise.other'),
            data: Exercise.count,
            url: exercises_path
        },
        {
            key: 'average_submissions',
            name: t('statistics.entries.exercises.average_number_of_submissions'),
            data: (Submission.count.to_f / Exercise.count).round(2)
        },
        {
            key: 'submissions_per_minute',
            name: t('statistics.entries.exercises.submissions_per_minute'),
            data: (Submission.where('created_at >= ?', DateTime.now - 1.hours).count.to_f / 60).round(2),
            unit: '/min'
        },
        {
            key: 'execution_environments',
            name: t('activerecord.models.execution_environment.other'),
            data: ExecutionEnvironment.count,
            url: execution_environments_path
        },
        {
            key: 'exercise_collections',
            name: t('activerecord.models.exercise_collection.other'),
            data: ExerciseCollection.count,
            url: exercise_collections_path
        }
    ]
  end

  def rfc_statistics
    [
        {
            key: 'rfcs',
            name: t('activerecord.models.request_for_comment.other'),
            data: RequestForComment.count,
            url: request_for_comments_path
        },
        {
            key: 'percent_solved',
            name: t('statistics.entries.request_for_comments.percent_solved'),
            data: (100.0 / RequestForComment.count * RequestForComment.where(solved: true).count).round(1),
            unit: '%',
            url: request_for_comments_path + '?q%5Bsolved_not_eq%5D=0'
        },
        {
            key: 'percent_soft_solved',
            name: t('statistics.entries.request_for_comments.percent_soft_solved'),
            data: (100.0 / RequestForComment.count * RequestForComment.unsolved.where(full_score_reached: true).count).round(1),
            unit: '%',
            url: request_for_comments_path
        },
        {
            key: 'percent_unsolved',
            name: t('statistics.entries.request_for_comments.percent_unsolved'),
            data: (100.0 / RequestForComment.count * RequestForComment.unsolved.count).round(1),
            unit: '%',
            url: request_for_comments_path + '?q%5Bsolved_not_eq%5D=1'
        },
        {
            key: 'comments',
            name: t('activerecord.models.comment.other'),
            data: Comment.count
        },
        {
            key: 'rfcs_with_comments',
            name: t('statistics.entries.request_for_comments.with_comments'),
            data: RequestForComment.joins('join "submissions" s on s.id = request_for_comments.submission_id
                join "files" f on f.context_id = s.id and f.context_type = \'Submission\'
                join "comments" c on c.file_id = f.id').group('request_for_comments.id').count.size
        }
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
            data: (Submission.where('created_at >= ?', DateTime.now - 1.hours).count.to_f / 60).round(2),
            unit: '/min',
            axis: 'right'
        }
    ]
  end

  def rfc_activity_live_data
    [
        {
            key: 'rfcs',
            name: t('activerecord.models.request_for_comment.other'),
            data: RequestForComment.count,
            url: request_for_comments_path
        },
        {
            key: 'rfcs_with_comments',
            name: t('statistics.entries.request_for_comments.with_comments'),
            data: RequestForComment.joins('join "submissions" s on s.id = request_for_comments.submission_id
                join "files" f on f.context_id = s.id and f.context_type = \'Submission\'
                join "comments" c on c.file_id = f.id').group('request_for_comments.id').count.size
        },
        {
            key: 'percent_solved',
            name: t('statistics.entries.request_for_comments.percent_solved'),
            data: (100.0 / RequestForComment.count * RequestForComment.where(solved: true).count).round(1),
            unit: '%',
            axis: 'right'
        },
        {
            key: 'percent_soft_solved',
            name: t('statistics.entries.request_for_comments.percent_soft_solved'),
            data: (100.0 / RequestForComment.count * RequestForComment.unsolved.where(full_score_reached: true).count).round(1),
            unit: '%',
            axis: 'right'
        },
        {
            key: 'percent_unsolved',
            name: t('statistics.entries.request_for_comments.percent_unsolved'),
            data: (100.0 / RequestForComment.count * RequestForComment.unsolved.count).round(1),
            unit: '%',
            axis: 'right'
        }
    ]
  end

end
