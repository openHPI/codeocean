# frozen_string_literal: true

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

  # DELETE /subscriptions/1
  # DELETE /subscriptions/1.json
  def destroy
    @subscription = Subscription.find(params[:id])
  rescue StandardError
    skip_authorization
    respond_to do |format|
      format.html { redirect_to request_for_comments_url, alert: t('subscriptions.subscription_not_existent') }
      format.json { render json: {message: t('subscriptions.subscription_not_existent')}, status: :not_found }
    end
  else
    authorize!
    rfc = @subscription.try(:request_for_comment)
    @subscription.deleted = true
    if @subscription.save
      respond_to do |format|
        format.html { redirect_to request_for_comment_url(rfc), notice: t('subscriptions.successfully_unsubscribed') }
        format.json { render json: {message: t('subscriptions.successfully_unsubscribed')}, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to request_for_comment_url(rfc), flash: {danger: t('shared.message_failure')} }
        format.json { render json: {message: t('shared.message_failure')}, status: :internal_server_error }
      end
    end
  end

  def set_subscription
    @subscription = Subscription.find(params[:id])
    authorize!
  end
  private :set_subscription

  def subscription_params
    current_user_id = current_user.try(:id)
    current_user_class_name = current_user.try(:class).try(:name)
    study_group_id = current_user.try(:current_study_group_id)
    if params[:subscription].present?
      params[:subscription].permit(:request_for_comment_id, :subscription_type).merge(user_id: current_user_id,
        user_type: current_user_class_name, study_group_id:, deleted: false)
    end
  end
  private :subscription_params
end
