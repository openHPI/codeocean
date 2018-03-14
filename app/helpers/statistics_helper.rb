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
            data: InternalUser.count
        },
        {
            key: 'external_users',
            name: t('activerecord.models.external_user.other'),
            data: ExternalUser.count
        }
    ]
  end

  def exercise_statistics
    [
        {
            key: 'exercises',
            name: t('activerecord.models.exercise.other'),
            data: Exercise.count
        },
        {
            key: 'average_submissions',
            name: t('statistics.entries.exercises.average_number_of_submissions'),
            data: Submission.count / Exercise.count
        }
    ]
  end

  def rfc_statistics
    [
        {
            key: 'rfcs',
            name: t('activerecord.models.request_for_comment.other'),
            data: RequestForComment.count
        },
        {
            key: 'percent_solved',
            name: t('statistics.entries.request_for_comments.percent_solved'),
            data: (100.0 / RequestForComment.count * RequestForComment.where(solved: true).count).round(2),
            unit: '%'
        },
        {
            key: 'comments',
            name: t('activerecord.models.comment.other'),
            data: Comment.count
        },
    ]
  end

end
