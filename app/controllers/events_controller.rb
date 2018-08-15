class EventsController < ApplicationController

  def authorize!
    authorize(@event || @events)
  end
  private :authorize!

  def create
    @event = Event.new(event_params)
    authorize!
    respond_to do |format|
      if @event.save
        format.html { head :created }
        format.json { head :created }
      else
        format.html { head :unprocessable_entity }
        format.json { head :unprocessable_entity }
      end
    end
  end

  def event_params
    params[:event]&.permit(:category, :data, :exercise_id, :file_id)
        &.merge(user_id: current_user&.id, user_type: current_user&.class.name)
  end
  private :event_params

end
