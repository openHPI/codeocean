# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def exercise_anomaly_detected
    collection = ExerciseCollection.new(name: 'Hello World', user: FactoryBot.create(:admin))
    anomalies = {49 => 879.325828, 51 => 924.870057, 31 => 1031.21233, 69 => 2159.182116}
    UserMailer.exercise_anomaly_detected(collection, anomalies)
  end
end
