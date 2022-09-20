# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def mail(*args)
    # used to prevent the delivery to pseudonymous users without a valid email address
    super if args.first[:to].present?
  end

  def activation_needed_email(user)
    @activation_url = activate_internal_user_url(user, token: user.activation_token)
    mail(subject: t('mailers.user_mailer.activation_needed.subject'), to: user.email)
  end

  def activation_success_email(*); end

  def reset_password_email(user)
    @reset_password_url = reset_password_internal_user_url(user, token: user.reset_password_token)
    mail(subject: t('mailers.user_mailer.reset_password.subject'), to: user.email)
  end

  def got_new_comment(comment, request_for_comment, commenting_user)
    # TODO: check whether we can take the last known locale of the receiver?
    token = AuthenticationToken.generate!(request_for_comment.user, request_for_comment.submission.study_group)
    @receiver_displayname = request_for_comment.user.displayname
    @commenting_user_displayname = commenting_user.displayname
    @comment_text = ERB::Util.html_escape comment.text
    @rfc_link = request_for_comment_url(request_for_comment, token: token.shared_secret)
    mail(
      subject: t('mailers.user_mailer.got_new_comment.subject',
        commenting_user_displayname: @commenting_user_displayname), to: request_for_comment.user.email
    )
  end

  def got_new_comment_for_subscription(comment, subscription, from_user)
    token = AuthenticationToken.generate!(subscription.user, subscription.study_group)
    @receiver_displayname = subscription.user.displayname
    @author_displayname = from_user.displayname
    @comment_text = ERB::Util.html_escape comment.text
    @rfc_link = request_for_comment_url(subscription.request_for_comment, token: token.shared_secret)
    @unsubscribe_link = unsubscribe_subscription_url(subscription)
    mail(
      subject: t('mailers.user_mailer.got_new_comment_for_subscription.subject',
        author_displayname: @author_displayname), to: subscription.user.email
    )
  end

  def send_thank_you_note(request_for_comment, receiver)
    token = AuthenticationToken.generate!(receiver, request_for_comment.submission.study_group)
    @receiver_displayname = receiver.displayname
    @author = request_for_comment.user.displayname
    @thank_you_note = ERB::Util.html_escape request_for_comment.thank_you_note
    @rfc_link = request_for_comment_url(request_for_comment, token: token.shared_secret)
    mail(subject: t('mailers.user_mailer.send_thank_you_note.subject', author: @author), to: receiver.email)
  end

  def exercise_anomaly_detected(exercise_collection, anomalies)
    @user = exercise_collection.user
    @receiver_displayname = exercise_collection.user.displayname
    @collection = exercise_collection
    @anomalies = anomalies
    mail(subject: t('mailers.user_mailer.exercise_anomaly_detected.subject'), to: exercise_collection.user.email)
  end

  def exercise_anomaly_needs_feedback(user, exercise, link)
    @receiver_displayname = user.displayname
    @exercise_title = exercise.title
    @link = link
    mail(subject: t('mailers.user_mailer.exercise_anomaly_needs_feedback.subject'), to: user.email)
  end
end
