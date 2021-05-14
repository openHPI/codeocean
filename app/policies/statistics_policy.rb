# frozen_string_literal: true

class StatisticsPolicy < AdminOnlyPolicy
  %i[graphs? user_activity? user_activity_history? rfc_activity? rfc_activity_history?].each do |action|
    define_method(action) { admin? }
  end
end
