# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper

  default from: "#{application_name} <codeocean@openhpi.de>"
  layout 'mailer'
end
