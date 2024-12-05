# frozen_string_literal: true

class ExternalUsersController < ApplicationController
  include TimeHelper

  def authorize!
    authorize(@user || @users)
  end
  private :authorize!

  def index
    @search = policy_scope(ExternalUser).ransack(params[:q], {auth_object: current_user})
    @users = @search.result.includes(:consumer).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show
    @user = ExternalUser.find(params[:id])
    authorize!
  end

  def working_time_query(tag = nil)
    deadline_scope_conditions = SubmissionPolicy::DeadlineScope.new(current_user, Submission).resolve

    "
    WITH filtered_submissions AS (
      #{deadline_scope_conditions.to_sql}
    )
    SELECT contributor_id,
           bar.exercise_id,
           max(score) as maximum_score,
           count(bar.id) as runs,
           sum(working_time_new) AS working_time,
           max(max_created_at) as created_at
    FROM
      (SELECT contributor_id,
              exercise_id,
              score,
              id,
              max_created_at,
              CASE
                  WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0'
                  ELSE working_time
              END AS working_time_new
       FROM
         (SELECT contributor_id,
                 exercise_id,
                 max(score) AS score,
                 max(filtered_submissions.created_at) FILTER (WHERE cause IN ('submit', 'assess', 'remoteSubmit', 'remoteAssess')) AS max_created_at,
                 filtered_submissions.id,
                 (filtered_submissions.created_at - lag(filtered_submissions.created_at) over (PARTITION BY contributor_id, exercise_id
                                                     ORDER BY filtered_submissions.created_at)) AS working_time
          FROM filtered_submissions
          JOIN exercises ON filtered_submissions.exercise_id = exercises.id
          WHERE #{ExternalUser.sanitize_sql(['contributor_id = ?', @user.id])}
            AND contributor_type = 'ExternalUser'
          GROUP BY exercise_id,
                   contributor_id,
                   filtered_submissions.id,
                   filtered_submissions.created_at
          ) AS foo
      ) AS bar
    #{tag.nil? ? '' : " JOIN exercise_tags et ON et.exercise_id = bar.exercise_id AND #{ExternalUser.sanitize_sql(['et.tag_id = ?', tag])}"}
    GROUP BY contributor_id,
             bar.exercise_id;
    "
  end

  def statistics
    @user = ExternalUser.find(params[:id])
    authorize!
    if params[:tag].present?
      tag = Tag.find(params[:tag])
      authorize(tag, :show?)
    end

    statistics = {}

    # We fake the statistics hash to be "submissions"
    # Available are: contributor_id, exercise_id, maximum_score, runs, working_time, created_at
    working_time_statistics = Submission.find_by_sql(working_time_query(tag&.id))
    ActiveRecord::Associations::Preloader.new(records: working_time_statistics, associations: [:exercise]).call
    working_time_statistics.each do |tuple|
      statistics[tuple.exercise] = tuple
    end

    render locals: {
      statistics:,
    }
  end

  def tag_statistics
    @user = ExternalUser.find(params[:id])
    authorize!

    statistics = []
    tags = ProxyExercise.new.get_user_knowledge_and_max_knowledge(@user, @user.participations.includes(:files, :tags, exercise_tags: [:tag]).uniq.compact)
    tags[:user_topic_knowledge].each_pair do |tag, value|
      statistics.append({key: tag.name.to_s, value: (100.0 / tags[:max_topic_knowledge][tag] * value).round,
        id: tag.id})
    end
    statistics.sort_by! {|item| -item[:value] }

    respond_to do |format|
      format.json { render(json: statistics) }
    end
  end
end
