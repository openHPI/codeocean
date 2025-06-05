# frozen_string_literal: true

class ReportsController < ApplicationController
  def create
    authorize!
    ReportMailer.with(reported_content:).report_content.deliver_later
    redirect_back(fallback_location: :root, notice: t('reports.reported'))
  end

  private

  def authorize!
    authorize(reported_content, policy_class: ReportPolicy)
  end

  def reported_content
    @reported_content ||= GlobalID::Locator.locate(params.require(:global_content_id))
  end
end
