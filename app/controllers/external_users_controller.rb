# frozen_string_literal: true

class ExternalUsersController < ApplicationController
  include TimeHelper

  before_action :require_user!

  def authorize!
    authorize(@user || @users)
  end
  private :authorize!

  def index
    @search = ExternalUser.ransack(params[:q], {auth_object: current_user})
    @users = @search.result.in_study_group_of(current_user).includes(:consumer).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show
    @user = ExternalUser.find(params[:id])
    authorize!
  end

  def working_time_query(tag = nil)
    "
    SELECT user_id,
           bar.exercise_id,
           max(score) as maximum_score,
           count(bar.id) as runs,
           sum(working_time_new) AS working_time
    FROM
      (SELECT user_id,
              exercise_id,
              score,
              id,
              CASE
                  WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0'
                  ELSE working_time
              END AS working_time_new
       FROM
         (SELECT user_id,
                 exercise_id,
                 max(score) AS score,
                 id,
                 (created_at - lag(created_at) over (PARTITION BY user_id, exercise_id
                                                     ORDER BY created_at)) AS working_time
          FROM submissions
          WHERE #{ExternalUser.sanitize_sql(['user_id = ?', @user.id])}
            AND user_type = 'ExternalUser'
          #{current_user.admin? ? '' : "AND #{ExternalUser.sanitize_sql(['study_group_id IN (?)', current_user.study_groups.pluck(:id)])} AND cause = 'submit'"}
          GROUP BY exercise_id,
                   user_id,
                   id
          ) AS foo
      ) AS bar
    #{tag.nil? ? '' : " JOIN exercise_tags et ON et.exercise_id = bar.exercise_id AND #{ExternalUser.sanitize_sql(['et.tag_id = ?', tag])}"}
    GROUP BY user_id,
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

    ApplicationRecord.connection.exec_query(working_time_query(tag&.id)).each do |tuple|
      tuple = tuple.merge('working_time' => format_time_difference(tuple['working_time']))
      statistics[tuple['exercise_id'].to_i] = tuple
    end

    render locals: {
      statistics:,
    }
  end

  def tag_statistics
    @user = ExternalUser.find(params[:id])
    authorize!

    statistics = []
    tags = ProxyExercise.new.get_user_knowledge_and_max_knowledge(@user, @user.participations.uniq.compact)
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
