class SubscriptionsController < ApplicationController

  def authorize!
    authorize(@subscription || @subscriptions)
  end
  private :authorize!

  # POST /subscriptions.json
  def create
    @subscription = Subscription.new(subscription_params)
    respond_to do |format|
      if @subscription.save
        format.json { render json: @subscription, status: :created }
      else
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
    authorize!
  end

  def set_subscription
    @subscription = Subscription.find(params[:id])
    authorize!
  end
  private :set_subscription

  def subscription_params
    current_user_id = current_user.try(:id)
    current_user_class_name = current_user.try(:class).try(:name)
    params[:subscription].permit(:request_for_comments, :subscription_type).merge(user_id: current_user_id, user_type: current_user_class_name)
  end
  private :subscription_params
end
