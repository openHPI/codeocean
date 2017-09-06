class SubscriptionController < ApplicationController

  def authorize!
    authorize(@submission || @submissions)
  end
  private :authorize!

  def set_subscription
    @subscription = Subscription.find(params[:id])
    authorize!
  end
  private :set_subscription

  def subscription_params
    current_user_id = current_user.try(:id)
    current_user_class_name = current_user.try(:class).try(:name)
    params[:subscription].permit(:request_for_comment, :type).merge(user_id: current_user_id, user_type: current_user_class_name)
  end
  private :subscription_params
end
