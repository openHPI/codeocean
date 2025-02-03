# frozen_string_literal: true

class EventsController < ApplicationController
  def create
    @event = Event.new(event_params)
    authorize!
    respond_to do |format|
      if @event.save
        format.html { head :created }
        format.json { head :created }
      else
        format.html { head :unprocessable_content }
        format.json { head :unprocessable_content }
      end
    end
  end

  private

  def authorize!
    authorize(@event || @events)
  end

  def event_params
    # The file ID processed here is the context of the exercise (template),
    # not in the context of the submission!
    params[:event]
      &.permit(:category, :data, :exercise_id, :file_id)
      &.merge(user: current_user, programming_group:, study_group_id: current_user.current_study_group_id)
  end

  def programming_group
    current_contributor if current_contributor.programming_group?
  end
end
